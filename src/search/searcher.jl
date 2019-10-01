"""
    Search object. It contains all the indexed data and related
configuration that allows for searches to be performed.
"""
mutable struct Searcher{T<:AbstractFloat,
                        E<:AbstractEmbedder{String, T},
                        I<:AbstractIndex}
    data::Ref
    config::SearchConfig                        # most of what is not actual data
    embedder::E                                 # needed to embed query
    index::I                                    # indexed search data
    search_trees::BKTree{String}                # suggestion structure
end


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
    build_searcher(dbdata, config)

Creates a Searcher from a searcher configuration `config::SearchConfig`.
"""
function build_searcher(dbdata, config)

    raw_document_iterator = (dbentry2text(dbentry, config.indexable_fields)
                             for dbentry in dbiterator(dbdata))

    # Pre-process documents
    flags = config.text_strip_flags | (config.stem_words ? stem_words : 0x0)
    language = get(STR_TO_LANG, config.language, DEFAULT_LANGUAGE)()
    prepared_documents = @op document_preparation(raw_document_iterator, flags, language)

    # Build corpus
    crps = @op build_corpus(prepared_documents, language, config.ngram_complexity)

    # Construct element type
    T = eval(config.vectors_eltype)

    # TODO(Corneliu) Separate embeddings as well from searchers
    # i.e. data, embeddings and indexes are separate an re-use each other

    # Get embedder (split into two separate call ways so that unused changed
    #               parameters do not influence the cache consistency)
    if config.vectors in [:word2vec, :glove, :conceptnet, :compressed]
        embedder = @op get_embedder(crps, T, config.vectors, config.embeddings_path,
                                    config.embeddings_kind, config.doc2vec_method,
                                    config.glove_vocabulary, config.sif_alpha,
                                    config.borep_dimension, config.borep_pooling_function,
                                    config.disc_ngram)
    elseif config.vectors in [:count, :tf, :tfidf, :bm25]
        embedder = @op get_embedder(crps, T, config.ngram_complexity,
                                    config.vectors, config.vectors_transform,
                                    config.vectors_dimension,
                                    config.bm25_kappa, config.bm25_beta)
    end

    # Calculate embeddings for each document
    embedded_documents = @op embed_all_documents(embedder, prepared_documents,
                                config.oov_policy, config.ngram_complexity)

    # Get search index type
    IndexType = get_search_index_type(config)

    # Build search index
    srchindex = @op IndexType(embedded_documents)

    # Build search tree (for suggestions)
    srchtree = @op get_bktree(config.heuristic, crps)

    # Build searcher
    srcher = @op Searcher(Ref(dbdata), config, embedder, srchindex, srchtree)

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


function get_bktree(heuristic, crps)
    lexicon = create_lexicon(crps, 1)
    if heuristic != nothing
        distance = get(HEURISTIC_TO_DISTANCE, heuristic, DEFAULT_DISTANCE)
        fdist = (x,y) -> evaluate(distance, x, y)
        return BKTree(fdist, collect(keys(lexicon)))
    else
        return BKTree{String}()
    end
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


function get_embedder(crps::Corpus,
                      ::Type{T},
                      ngram_complexity::Int,
                      vectors::Symbol,
                      vectors_transform::Symbol,
                      vectors_dimension::Int,
                      bm25_kappa::Int,
                      bm25_beta::Float64
                     ) where T<:AbstractFloat
    # Initialize dtm
    dtm = DocumentTermMatrix{T}(crps, ngram_complexity=ngram_complexity)

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

function get_embedder(crps::Corpus,
                      ::Type{T},
                      vectors::Symbol,
                      embeddings_path::String,
                      embeddings_kind::Symbol,
                      doc2vec_method::Symbol,
                      glove_vocabulary,
                      sif_alpha::Float64,
                      borep_dimension::Int,
                      borep_pooling_function::Symbol,
                      disc_ngram::Int,
                     ) where T<:AbstractFloat
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
        return SIFEmbedder(embeddings, create_lexicon(crps, 1), sif_alpha)
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


function build_corpus(documents::Vector{Vector{String}},
                      language::Languages.Language,
                      ngram_complexity::Int)
    language_type = typeof(language)
    @assert language_type in SUPPORTED_LANGUAGES "Language $language_type is not supported"

    docs = Vector{StringDocument{String}}()
    for sentences in documents
        doc = StringDocument(join(sentences, " "))
        StringAnalysis.language!(doc, language)
        push!(docs, doc)
    end
    crps = Corpus(docs)

    # Update lexicon, inverse index
    update_lexicon!(crps, ngram_complexity)
    update_inverse_index!(crps, ngram_complexity)
    return crps
end
