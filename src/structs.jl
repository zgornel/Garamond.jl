##############################
# Interface for the Searcher #
##############################

# Searcher structures
mutable struct Searcher{D<:AbstractDocument, E, M<:AbstractSearchModel}
    config::SearchConfig                        # most of what is not actual data
    corpus::Corpus{String,D}                    # corpus
    embedder::E                                 # needed to embed query
    search_data::Dict{Symbol, M}                # actual indexed search data
    search_trees::Dict{Symbol, BKTree{String}}  # for suggestions
end


# Useful methods
id(srcher::Searcher{D,E,M}) where {D,E,M} = srcher.config.id

description(srcher::Searcher{D,E,M}) where {D,E,M} = srcher.config.description

isenabled(srcher::Searcher{D,E,M}) where {D,E,M} = srcher.config.enabled

disable!(srcher::Searcher) = begin
    srcher.config.enabled = false
    return srcher
end

enable!(srcher::Searcher) = begin
    srcher.config.enabled = true
    return srcher
end

# Show method
show(io::IO, srcher::Searcher{D,E,M}) where {D,E,M} = begin
    printstyled(io, "Searcher for $(id(srcher)), ")
    _status = ifelse(isenabled(srcher), "enabled", "disabled")
    _status_color = ifelse(isenabled(srcher), :light_green, :light_black)
    printstyled(io, "$_status", color=_status_color, bold=true)
    printstyled(io, ", ")
    # Get embeddings type string
    if E <: Word2Vec.WordVectors
        _embedder = "Word2Vec"
    elseif E <: Glowe.WordVectors
        _embedder = "GloVe"
    elseif E <: ConceptnetNumberbatch.ConceptNet
        _embedder = "Conceptnet"
    elseif E <: Dict{Symbol, <:StringAnalysis.LSAModel}
        _embedder = "DTV+LSA"
    elseif E <: Dict{Symbol, <:StringAnalysis.RPModel}
        _embedder = "DTV"
        if srcher.config.vectors_transform==:rp
            _embedder *= "+RP"
        end
    else
        _embedder = "<Unknown>"
    end
    printstyled(io, "$_embedder", bold=true)
    printstyled(io, ", ")
    # Get model type string
    if M <: NaiveEmbeddingModel
        _model_type = "Naive"
    elseif M <: BruteTreeEmbeddingModel
        _model_type = "Brute-Tree"
    elseif M<: KDTreeEmbeddingModel
        _model_type = "KD-Tree"
    elseif M <: HNSWEmbeddingModel
        _model_type = "HNSW"
    else
        _model_type = "<Unknown>"
    end
    printstyled(io, "$_model_type", bold=true)
    #printstyled(io, "$(description(srcher))", color=:normal)
    printstyled(io, ", $(length(srcher.search_data[:data])) embedded documents")
end


"""
    build_searcher(sconf)

Creates a Searcher from a SearchConfig.
"""
function build_searcher(sconf::SearchConfig)
    # Parse file
    documents, metadata_vector = sconf.parser(sconf.data_path)
    # Create metadata documents; output is Vector{Vector{String}}
    documents_meta = meta2sv.(metadata_vector)
    # Build document and document metadata corpora
    # Note: the metadata is kept as well for the purpose of
    #       converying information regarding what is being
    #       searched. The only use for it is when displaying
    crps = build_corpus(documents, DOCUMENT_TYPE, metadata_vector)
    crps_meta = build_corpus(documents_meta, DOCUMENT_TYPE, metadata_vector)
    # Pre-process documents
    prepare!.(crps, sconf.text_strip_flags |
              (sconf.stem_words ? stem_words : 0x0))
    prepare!.(crps_meta, sconf.metadata_strip_flags |
              (sconf.stem_words ? stem_words : 0x0))
    # Update lexicons
    update_lexicon!(crps)
    update_lexicon!(crps_meta)
    # Construct element type
    T = eval(sconf.vectors_eltype)
    # Get search model types
    sconf.search_model == :naive && (SearchModel = NaiveEmbeddingModel)
    sconf.search_model == :brutetree && (SearchModel = BruteTreeEmbeddingModel)
    sconf.search_model == :kdtree && (SearchModel = KDTreeEmbeddingModel)
    sconf.search_model == :hnsw && (SearchModel = HNSWEmbeddingModel)
    # Load or construct document embedder data
    if sconf.vectors in [:count, :tf, :tfidf, :bm25]
        # Calculate term importances
        dtm = DocumentTermMatrix{T}(crps)
        dtm_meta = DocumentTermMatrix{T}(crps_meta)
        # Get document-term statistic function
        sconf.vectors == :count && (fstatistic = identity)
        sconf.vectors == :tf && (fstatistic = StringAnalysis.tf!)
        sconf.vectors == :tfidf && (fstatistic = StringAnalysis.tf_idf!)
        sconf.vectors == :bm25 && (fstatistic = StringAnalysis.bm_25!)
        # Apply document-term statistic function
        fstatistic(dtm.dtm)
        fstatistic(dtm_meta.dtm)
        # Embedder
        local SubspaceModel, dims
        sconf.vectors_transform == :none && (SubspaceModel = RPModel; dims = 0)
        sconf.vectors_transform == :rp && (SubspaceModel = RPModel; dims = sconf.vectors_dimension)
        sconf.vectors_transform == :lsa && (SubspaceModel = LSAModel; dims = sconf.vectors_dimension)
        embedder = Dict(:data => SubspaceModel(dtm, k=dims, stats=sconf.vectors),
                        :metadata => SubspaceModel(dtm_meta, k=dims, stats=sconf.vectors))
        _srchdata = SearchModel(embed_document(embedder[:data], dtm)')
        _srchdata_meta = SearchModel(embed_document(embedder[:metadata], dtm_meta)')
    # Semantic searcher
    elseif sconf.vectors in [:word2vec, :glove, :conceptnet]
        # Read word embeddings
        if sconf.vectors == :conceptnet
            embedder = load_embeddings(sconf.embeddings_path,
                languages=[Languages.English()], data_type=T)
        elseif sconf.vectors == :word2vec
            embedder = Word2Vec.wordvectors(sconf.embeddings_path, T,
                kind=sconf.embeddings_kind, normalize=false)
        elseif sconf.vectors == :glove
            embedder = Glowe.wordvectors(sconf.embeddings_path, T,
                kind=sconf.embeddings_kind,
                vocabulary=sconf.glove_vocabulary,
                normalize=false, load_bias=false)
        end
        # Construct document data model
        _srchdata = SearchModel(hcat(
                (embed_document(embedder, crps.lexicon, doc, embedding_method=sconf.doc2vec_method)
                 for doc in documents)...))
        # Construct document metadata model
        _srchdata_meta = SearchModel(hcat(
                (embed_document(embedder, crps_meta.lexicon, doc, embedding_method=sconf.doc2vec_method)
                 for doc in documents_meta)...))
    end
    # Build search trees (for suggestions)
    if sconf.heuristic != nothing
        distance = get(HEURISTIC_TO_DISTANCE, sconf.heuristic, DEFAULT_DISTANCE)
        _srchtree_data = BKTree((x,y)->evaluate(distance, x, y),
                                collect(keys(crps.lexicon)))
        _srchtree_meta = BKTree((x,y)->evaluate(distance, x, y),
                                collect(keys(crps_meta.lexicon)))
    else
        _srchtree_data = BKTree{String}()
        _srchtree_meta = BKTree{String}()
    end
    # Remove corpus data if keep_data is false
    if !sconf.keep_data
        crps = Corpus(DOCUMENT_TYPE[])
    end
    # Build searcher
    srcher = Searcher(sconf, crps, embedder,
                      Dict(:data=>_srchdata, :metadata=>_srchdata_meta),
                      Dict(:data=>_srchtree_data, :metadata=>_srchtree_meta)
                     )
    return srcher
end



##################
# Load searchers #
##################
# Loading process flow:
#   1. Parse configuration file using `load_search_configs`
#   2. The resulting Vector{SearchConfig} is passed to `load_searchers`
#      (each SearchConfig contains the data filepath, corpus name etc.
#   3. Parse the data file, obtain Corpus and create specified Searcher
function load_searchers(paths)
    sconfs = load_search_configs(paths)
    srchers = load_searchers(sconfs)
    return srchers
end

function load_searchers(sconfs::Vector{SearchConfig})
    srchers = [build_searcher(sconf) for sconf in sconfs]
    return srchers
end



# Indexing for vectors of searchers
getindex(srchers::V, an_id::StringId) where {V<:Vector{<:Searcher{D,E,M}
        where D<:AbstractDocument where E where M<:AbstractSearchModel}} = begin
    idxs = Int[]
    for (i, srcher) in enumerate(srchers)
        id(srcher) == an_id && push!(idxs, i)
    end
    return srchers[idxs]
end

getindex(srchers::V, an_id::String) where {V<:Vector{<:Searcher{D,E,M}
        where D<:AbstractDocument where E where M<:AbstractSearchModel}} =
    srchers[StringId(an_id)]
