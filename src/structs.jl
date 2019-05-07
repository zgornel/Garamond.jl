##############################
# Interface for the Searcher #
##############################

# Searcher structures
"""
    Search object. It contains all the indexed data and related
configuration that allows for searches to be performed.
"""
mutable struct Searcher{T<:AbstractFloat, D<:AbstractDocument, E, I<:AbstractIndex}
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
        ) where {D<:AbstractDocument, E, I<:AbstractIndex} =
    Searcher{get_embedding_eltype(embedder), D, E, I}(
        config, corpus, embedder, index, search_trees)


"""
    get_embedding_eltype(embeddings)

Function that returns the type of the embeddings' elements. The type is useful to
generate score vectors. If the element type is and `Int8` (ConceptNet compressed),
the returned type is the DEFAULT_EMBEDDING_TYPE.
"""
# Get embedding element types
get_embedding_eltype(::Word2Vec.WordVectors{S,T,H}) where
    {S<:AbstractString, T<:Real, H<:Integer} = T

get_embedding_eltype(::Glowe.WordVectors{S,T,H}) where
    {S<:AbstractString, T<:Real, H<:Integer} = T

get_embedding_eltype(::ConceptNet{L,K,E}) where
    {L<:Language, K<:AbstractString, E<:AbstractFloat} = E

get_embedding_eltype(::ConceptNet{L,K,E}) where
    {L<:Language, K<:AbstractString, E<:Integer} = DEFAULT_EMBEDDING_ELEMENT_TYPE

get_embedding_eltype(::RPModel{S,T,A,H}) where
    {S<:AbstractString, T<:AbstractFloat, A<:AbstractMatrix{T}, H<:Integer} = T

get_embedding_eltype(::LSAModel{S,T,A,H}) where
    {S<:AbstractString, T<:AbstractFloat, A<:AbstractMatrix{T}, H<:Integer} = T

get_embedding_eltype(::Union{<:RPModel{S,T,A,H}, <:LSAModel{S,T,A,H}}) where
    {S<:AbstractString, T<:AbstractFloat, A<:AbstractMatrix{T}, H<:Integer} = T


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
        id(srcher) == an_id && push!(idxs, i)
    end
    return srchers[idxs]
end

function getindex(srchers::V, an_id::String
        ) where {V<:Vector{<:Searcher{T,D,E,I}
          where T<:AbstractFloat where D<:AbstractDocument
          where E where I<:AbstractIndex}}
    srchers[StringId(an_id)]
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
    document_sentences_prepared = @op document_preparation(documents_sentences, flags)
    metadata_sentences_prepared = @op document_preparation(metadata_sentences, flags_meta)

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
                            sconf.embeddings_kind, sconf.glove_vocabulary, T)

    elseif sconf.vectors in [:count, :tf, :tfidf, :bm25]
        embedder = @op get_embedder(sconf.vectors, sconf.vectors_transform,
                            sconf.bm25_kappa, sconf.bm25_beta,
                            sconf.vectors_dimension, documents, lex, T)
    end

    # Calculate embeddings for each document
    embedded_documents = @op embed_all_documents(embedder, lex, merged_sentences,
                                sconf.doc2vec_method, sconf.sif_alpha)
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

function document_preparation(documents, flags)
    map(sentences->prepare.(sentences, flags), documents)
end

function embed_all_documents(embedder, lexicon, documents, method, alpha)
    hcat((embed_document(embedder, lexicon, doc,
                       embedding_method=method,
                       sif_alpha=alpha)
          for doc in documents)...)
end

function get_search_index_type(sconf::SearchConfig)
    # Get search index types
    search_index = sconf.search_index
    search_index == :naive && return NaiveIndex
    search_index == :brutetree && return BruteTreeIndex
    search_index == :kdtree && return KDTreeIndex
    search_index == :hnsw && return HNSWIndex
end

function get_embedder(vectors, vectors_transform, bm25_kappa,
                      bm25_beta, vectors_dimension, documents,
                      lex, ::Type{T}) where T<:AbstractFloat
    dtm = DocumentTermMatrix{T}(Corpus(documents), lex)
    vectors_transform == :none &&
        return RPModel(dtm, k=0, stats=vectors,
                       κ=bm25_kappa,
                       β=bm25_beta)
    vectors_transform == :rp &&
        return RPModel(dtm, k=vectors_dimension,
                       stats=vectors,
                       κ=bm25_kappa,
                       β=bm25_beta)
    vectors_transform == :lsa &&
        return LSAModel(dtm, k=vectors_dimension,
                        stats=vectors,
                        κ=bm25_kappa,
                        β=bm25_beta)
end

function get_embedder(vectors, embeddings_path, embeddings_kind,
                      glove_vocabulary, ::Type{T}) where T<:AbstractFloat
    # Read word embeddings
    if vectors == :conceptnet
        return load_embeddings(embeddings_path,
                               languages=[Languages.English()],
                               data_type=T)
    elseif vectors == :word2vec
        return Word2Vec.wordvectors(embeddings_path, T,
                                    kind=embeddings_kind,
                                    normalize=false)
    elseif vectors == :glove
        return Glowe.wordvectors(embeddings_path, T,
                                 kind=embeddings_kind,
                                 vocabulary=glove_vocabulary,
                                 normalize=false, load_bias=false)
    end
end
