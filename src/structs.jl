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
    config::SearchConfig                        # most of what is not actual data
    corpus::Corpus{String,D}                    # corpus
    embedder::E                                 # needed to embed query
    index::I                                    # indexed search data
    search_trees::BKTree{String}                # suggestion structure
end

Searcher(config::SearchConfig,
         corpus::Corpus{String, D},
         embedder::E,
         index::I,
         search_trees::BKTree{String}
        ) where {T, D<:AbstractDocument, E<:AbstractEmbedder{String,T}, I<:AbstractIndex} =
    Searcher{T, D, E, I}(config, corpus, embedder, index, search_trees)


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
function getindex(srchers::V, an_id::StringId
        ) where {V<:Vector{<:Searcher{T,D,E,I}
          where T<:AbstractFloat where D<:AbstractDocument
          where E where I<:AbstractIndex}}
    idxs = Int[]
    for (i, srcher) in enumerate(srchers)
        isequal(id(srcher), an_id) && push!(idxs, i)
    end
    return srchers[idxs]
end

function getindex(srchers::V, an_id::String
        ) where {V<:Vector{<:Searcher{T,D,E,I}
          where T<:AbstractFloat where D<:AbstractDocument
          where E where I<:AbstractIndex}}
    getindex(srchers, StringId(an_id))
end


##################
# Load searchers #
##################
"""
    load_searchers(configs)

Loads/builds searchers using the information provided by `configs`. The
latter can be either a path, a vector of paths to searcher configuration file(s)
or a vector of `SearchConfig` objects.

Loading process flow:
   1. Parse configuration files using `load_search_configs` (if `configs`
      contains paths to configuration files)
   2. The resulting `Vector{SearchConfig}` is passed to `load_searchers`
      (each `SearchConfig` contains the data filepath, parameters etc.)
   3. Each searcher is build using `build_searcher` and a vector of
      searcher objects is returned.
"""
function load_searchers(configs)
    sconfs = load_search_configs(configs)  # load searcher configs
    srchers = load_searchers(sconfs)       # load searchers
    return srchers
end

function load_searchers(configs::Vector{SearchConfig})
    srchers = [build_searcher(sconf) for sconf in configs]  # build searchers
    return srchers
end


"""
    build_searcher(sconf::SearchConfig)

Creates a Searcher from a searcher configuration `sconf`.
"""
function build_searcher(sconf::SearchConfig)
    # Parse file
    documents_sentences, metadata_vector = sconf.parser(sconf.data_path)

    # Create metadata sentences
    metadata_sentences = @op meta2sv(metadata_vector)

    # Pre-process documents
    flags = sconf.text_strip_flags | (sconf.stem_words ? stem_words : 0x0)
    flags_meta = sconf.metadata_strip_flags | (sconf.stem_words ? stem_words : 0x0)
    language = get(STR_TO_LANG, sconf.language, DEFAULT_LANGUAGE)()
    document_sentences_prepared = @op document_preparation(documents_sentences,
                                        flags, language)
    metadata_sentences_prepared = @op document_preparation(metadata_sentences,
                                        flags_meta, language)

    # Build corpus
    merged_sentences = @op merge_documents(document_sentences_prepared,
                                           metadata_sentences_prepared)
    full_crps = @op build_corpus(merged_sentences, metadata_vector, DOCUMENT_TYPE)
    crps, documents = @op get_corpus_documents(full_crps, sconf.keep_data)
    lex = @op lexicon(full_crps)

    # Construct element type
    T = eval(sconf.vectors_eltype)

    # Get embedder (split into two separate call ways so that unused changed
    #               parameters do not influence the cache consistency)
    if sconf.vectors in [:word2vec, :glove, :conceptnet]
        embedder = @op get_embedder(sconf.vectors, sconf.embeddings_path,
                            sconf.embeddings_kind, sconf.doc2vec_method,
                            sconf.glove_vocabulary, sconf.sif_alpha,
                            sconf.borep_dimension, sconf.borep_pooling_function,
                            sconf.disc_ngram, lex, T)
    elseif sconf.vectors in [:count, :tf, :tfidf, :bm25]
        embedder = @op get_embedder(sconf.vectors, sconf.vectors_transform,
                            sconf.vectors_dimension, sconf.bm25_kappa,
                            sconf.bm25_beta, documents, lex, T)
    end

    # Calculate embeddings for each document
    embedded_documents = @op embed_all_documents(embedder, merged_sentences)

    # Get search index type
    IndexType = get_search_index_type(sconf)

    # Build search index
    srchindex = @op IndexType(embedded_documents)

    # Build search tree (for suggestions)
    srchtree = @op get_bktree(sconf.heuristic, lex)

    # Build searcher
    srcher = @op Searcher(sconf, crps, embedder, srchindex, srchtree)

    # Set Dispatcher logging level to warning
    setlevel!(getlogger("Dispatcher"), "warn")

    # Prepare for dispatch graph execution
    endpoint = srcher
    uncacheable = [srcher]
    sconf.search_index == :hnsw && push!(uncacheable, srchindex)

    # Execute dispatch graph
    srcher = extract(
                run_dispatch_graph(endpoint, uncacheable,
                    sconf.cache_directory,
                    sconf.cache_compression))
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
    !keep_data && (crps.documents = DOCUMENT_TYPE[])
    return crps, docs
end

function document_preparation(documents, flags, language)
    map(sentences->prepare.(sentences, flags, language=language), documents)
end

function embed_all_documents(embedder, documents)
    hcat((document2vec(embedder, doc) for doc in documents)...)
end

function get_search_index_type(sconf::SearchConfig)
    # Get search index types
    search_index = sconf.search_index
    search_index == :naive && return NaiveIndex
    search_index == :brutetree && return BruteTreeIndex
    search_index == :kdtree && return KDTreeIndex
    search_index == :hnsw && return HNSWIndex
end

function get_embedder(vectors::Symbol, vectors_transform::Symbol,
                      vectors_dimension::Int, bm25_kappa::Int, bm25_beta::Float64,
                      documents, lex, ::Type{T}) where T<:AbstractFloat
    # Initialize dtm
    dtm = DocumentTermMatrix{T}(Corpus(documents), lex)

    local model
    if vectors_transform == :none
        model = RPModel(dtm, k=0, stats=vectors, κ=bm25_kappa, β=bm25_beta)
    elseif vectors_transform == :rp
        model = RPModel(dtm, k=vectors_dimension, stats=vectors, κ=bm25_kappa, β=bm25_beta)
    elseif vectors_transform == :lsa
        model = LSAModel(dtm, k=vectors_dimension, stats=vectors, κ=bm25_kappa, β=bm25_beta)
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
