#TODO(Corneliu) Update documentation of the functions
#
##############################
# Interface for the Searcher #
##############################

# Searcher structures
"""
    Search object. It contains all the indexed data and related
configuration that allows for searches to be performed.
"""
mutable struct Searcher{T<:AbstractFloat,
                        D<:AbstractDocument,
                        E<:AbstractEmbedder{String, T},
                        I<:AbstractIndex}
    data::Ref
    config::SearchConfig                        # most of what is not actual data
    corpus::Corpus{String,D}                    # corpus
    embedder::E                                 # needed to embed query
    index::I                                    # indexed search data
    search_trees::BKTree{String}                # suggestion structure
end


Searcher(data::Ref,
         config::SearchConfig,
         corpus::Corpus{String, D},
         embedder::E,
         index::I,
         search_trees::BKTree{String}
        ) where {T, D<:AbstractDocument, E<:AbstractEmbedder{String,T}, I<:AbstractIndex} =
    Searcher{T, D, E, I}(data, config, corpus, embedder, index, search_trees)


# Useful methods
id(srcher::Searcher) = srcher.config.id

description(srcher::Searcher) = srcher.config.description

isenabled(srcher::Searcher) = srcher.config.enabled

disable!(srcher::Searcher) = begin
    srcher.config.enabled = false
    return srcher
end

enable!(srcher::Searcher) = begin
    srcher.config.enabled = true
    return srcher
end


# Indexing for vectors of searchers
function getindex(srchers::AbstractVector{Searcher}, an_id::StringId)
    idxs = Int[]
    for (i, srcher) in enumerate(srchers)
        isequal(id(srcher), an_id) && push!(idxs, i)
    end
    return srchers[idxs]
end

getindex(srchers::AbstractVector{Searcher}, an_id::String) = getindex(srchers, StringId(an_id))


"""
    load_search_env(config_file)

Creates a search environment using the information provided by `config_file`.
"""
function load_search_env(config_file)
    data_loader, data_path, configs = parse_configuration(config_file)
    #TODO(Corneliu) Review this i.e. fieldmaps should be removed (with removal of METADATA)
    dbdata, fieldmaps = data_loader(data_path)
    srchers = [build_searcher(dbdata, fieldmaps, config) for config in configs]  # build searchers
    return dbdata, fieldmaps, srchers
end


"""
    build_searcher(dbdata, fieldmaps, config)

Creates a Searcher from a searcher configuration `config::SearchConfig`.
"""
function build_searcher(dbdata, fieldmaps, config)

    documents_sentences = [dbentry2sentence(dbentry, fieldmaps.data_fields)
                           for dbentry in dbiterator(dbdata)]
    metadata_vector = [dbentry2metadata(dbentry, fieldmaps.metadata_fields, language=config.language)
                       for dbentry in dbiterator(dbdata)]

    # Create metadata sentences
    metadata_sentences = @op meta2sv(metadata_vector, config.metadata_to_index)

    # Pre-process documents
    flags = config.text_strip_flags | (config.stem_words ? stem_words : 0x0)
    flags_meta = config.metadata_strip_flags | (config.stem_words ? stem_words : 0x0)
    language = get(STR_TO_LANG, config.language, DEFAULT_LANGUAGE)()
    document_sentences_prepared = @op document_preparation(documents_sentences,
                                        flags, language)
    metadata_sentences_prepared = @op document_preparation(metadata_sentences,
                                        flags_meta, language)

    # Build corpus
    merged_sentences = @op merge_documents(document_sentences_prepared,
                                           metadata_sentences_prepared)
    full_crps = @op build_corpus(merged_sentences, metadata_vector, config.ngram_complexity)
    crps, documents = @op get_corpus_documents(full_crps, config.keep_data)
    lex = @op lexicon(full_crps)
    lex_1gram = @op create_lexicon(full_crps, 1)
    # Construct element type
    T = eval(config.vectors_eltype)

    # TODO(Corneliu) Separate embeddings as well from searchers
    # i.e. data, embeddings and indexes are separate an re-use each other

    # Get embedder (split into two separate call ways so that unused changed
    #               parameters do not influence the cache consistency)
    if config.vectors in [:word2vec, :glove, :conceptnet, :compressed]
        embedder = @op get_embedder(config.vectors, config.embeddings_path,
                            config.embeddings_kind, config.doc2vec_method,
                            config.glove_vocabulary, config.sif_alpha,
                            config.borep_dimension, config.borep_pooling_function,
                            config.disc_ngram, lex_1gram, T)
    elseif config.vectors in [:count, :tf, :tfidf, :bm25]
        embedder = @op get_embedder(config.vectors, config.vectors_transform,
                            config.vectors_dimension, config.ngram_complexity,
                            config.bm25_kappa, config.bm25_beta,
                            documents, lex, T)
    end

    # Calculate embeddings for each document
    embedded_documents = @op embed_all_documents(embedder, merged_sentences,
                                config.oov_policy, config.ngram_complexity)

    # Get search index type
    IndexType = get_search_index_type(config)

    # Build search index
    srchindex = @op IndexType(embedded_documents)

    # Build search tree (for suggestions)
    srchtree = @op get_bktree(config.heuristic, lex_1gram)

    # Build searcher
    srcher = @op Searcher(Ref(dbdata), config, crps, embedder, srchindex, srchtree)

    # Set Dispatcher logging level to warning
    setlevel!(getlogger("Dispatcher"), "warn")

    # Prepare for dispatch graph execution
    endpoint = srcher
    uncacheable = [srcher]
    config.search_index == :hnsw && push!(uncacheable, srchindex)

    # Execute dispatch graph
    srcher = extract(
                run_dispatch_graph(endpoint, uncacheable,
                    config.cache_directory,
                    config.cache_compression))
    @debug "* Loaded: $srcher."
    return srcher
end


# Functions used throughout the searcher build process
extract(r) = fetch(r[1].result.value)


function run_dispatch_graph(endpoint, uncacheable, cachedir::Nothing, compression)
    run!(AsyncExecutor(), [endpoint])
end

function run_dispatch_graph(endpoint, uncacheable, cachedir::AbstractString, compression)
graph = DispatchGraph(endpoint)
    DispatcherCache.run!(AsyncExecutor(), graph, [endpoint], uncacheable,
                         cachedir=cachedir, compression=compression)
end


function get_bktree(heuristic, lexicon)
    if heuristic != nothing
        distance = get(HEURISTIC_TO_DISTANCE, heuristic, DEFAULT_DISTANCE)
        fdist = (x,y) -> evaluate(distance, x, y)
        return BKTree(fdist, collect(keys(lexicon)))
    else
        return BKTree{String}()
    end
end


function merge_documents(docs, docs_meta)
    [vcat(doc, meta) for (doc, meta) in zip(docs, docs_meta)]
end


function get_corpus_documents(crps, keep_data)
    docs = documents(crps)
    !keep_data && (crps.documents = [])
    return crps, docs
end


function document_preparation(documents, flags, language)
    map(sentences->prepare.(sentences, flags, language=language), documents)
end


function embed_all_documents(embedder, documents, oov_policy, ngram_complexity)
    hcat((document2vec(embedder, doc, oov_policy;
                       ngram_complexity=ngram_complexity)[1]
          for doc in documents)...)
end


function get_search_index_type(config::SearchConfig)
    # Get search index types
    search_index = config.search_index
    search_index == :naive && return NaiveIndex
    search_index == :brutetree && return BruteTreeIndex
    search_index == :kdtree && return KDTreeIndex
    search_index == :hnsw && return HNSWIndex
end


function get_embedder(vectors::Symbol, vectors_transform::Symbol,
                      vectors_dimension::Int, ngram_complexity::Int,
                      bm25_kappa::Int, bm25_beta::Float64,
                      documents, lex, ::Type{T}) where T<:AbstractFloat
    # Initialize dtm
    dtm = DocumentTermMatrix{T}(Corpus(documents), lex, ngram_complexity=ngram_complexity)

    local model
    if vectors_transform == :none
        model = RPModel(dtm, k=0, stats=vectors,
                        ngram_complexity=ngram_complexity,
                        κ=bm25_kappa, β=bm25_beta)
    elseif vectors_transform == :rp
        model = RPModel(dtm, k=vectors_dimension, stats=vectors,
                        ngram_complexity=ngram_complexity,
                        κ=bm25_kappa, β=bm25_beta)
    elseif vectors_transform == :lsa
        model = LSAModel(dtm, k=vectors_dimension,
                         ngram_complexity=ngram_complexity,
                         stats=vectors, κ=bm25_kappa, β=bm25_beta)
    end

    # Construct embedder
    return DTVEmbedder(model)
end

function get_embedder(vectors::Symbol, embeddings_path::String, embeddings_kind::Symbol,
                      doc2vec_method::Symbol, glove_vocabulary, sif_alpha::Float64,
                      borep_dimension::Int, borep_pooling_function::Symbol, disc_ngram::Int,
                      lex, ::Type{T}) where T<:AbstractFloat
    # Read word embeddings
    local embeddings
    if vectors == :conceptnet
        embeddings = load_embeddings(embeddings_path,
                        languages=[Languages.English()],
                        data_type=T)
    elseif vectors == :word2vec
        embeddings = Word2Vec.wordvectors(embeddings_path, T,
                        kind=embeddings_kind,
                        normalize=false)
    elseif vectors == :glove
        embeddings = Glowe.wordvectors(embeddings_path, T,
                        kind=embeddings_kind,
                        vocabulary=glove_vocabulary,
                        normalize=false,
                        load_bias=false)
    elseif vectors == :compressed
        embeddings = EmbeddingsAnalysis.compressedwordvectors(
                        embeddings_path, T, kind=embeddings_kind)
    end

    # Construct embedder based on document2vec method
    if doc2vec_method == :boe
        return BOEEmbedder(embeddings)
    elseif doc2vec_method == :sif
        return SIFEmbedder(embeddings, lex, sif_alpha)
    elseif doc2vec_method == :borep
        return BOREPEmbedder(embeddings,
                    dim=borep_dimension,
                    pooling_function=borep_pooling_function)
    elseif doc2vec_method == :cpmean
        return CPMeanEmbedder(embeddings)
    elseif doc2vec_method == :disc
        return DisCEmbedder(embeddings, n=disc_ngram)
    end
end
