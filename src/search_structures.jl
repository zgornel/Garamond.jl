###########################
# Term Counting structure #
###########################
abstract type AbstractDocumentCount <: AbstractSearchData
end

struct TermCounts <: AbstractDocumentCount
    column_indices::Dict{String, Int}
    values::SparseMatrixCSC{DEFAULT_COUNT_ELEMENT_TYPE, Int64}
end

# Useful methods
length(tc::TermCounts) = size(tc.values, 1)  # number of documents

# Show method
show(io::IO, tc::TermCounts) = begin
    m, n = size(tc.values)
    print("Term importances for $m documents, $n unique terms.")
end



#################################################
# Interface for the Searcher (classic, semantic #
#################################################

# Searcher structures
mutable struct Searcher{D<:AbstractDocument,
                        E,
                        M<:AbstractSearchData} <: AbstractSearcher
    config::SearchConfig                        # most of what is not actual data
    corpus::Corpus{D}                           # corpus
    embeddings::E                               # needed to embed query
    search_data::Dict{Symbol, M}                # actual search data (classic and semantic)
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
    _srcher_type = ifelse(M<:AbstractDocumentCount,
                          "Classic Searcher",
                          "Semantic Searcher")
    printstyled(io, "$_srcher_type, ")
    printstyled(io, "[$(id(srcher))] ", color=:cyan)
    _status = ifelse(isenabled(srcher), "enabled", "disabled")
    _status_color = ifelse(isenabled(srcher), :light_green, :light_black)
    printstyled(io, "[$_status]", color=_status_color)
    # Get embeddings type string
    if E <: WordVectors
        _embs_type = "word2vec"
    elseif E <: ConceptNet
        _embs_type = "conceptnet"
    elseif E <: Nothing
        _embs_type = "no embeddings"
    else
        _embs_type = "unknown embeddings"
    end
    # Get model type string
    if M <: AbstractDocumentCount
        _model_type = "tf/tf-idf"
    elseif M <: NaiveEmbeddingModel
        _model_type = "naive model"
    elseif M <: BruteTreeEmbeddingModel
        _model_type = "brute tree model"
    elseif M<: KDTreeEmbeddingModel
        _model_type = "kd-tree model"
    elseif M <: HNSWEmbeddingModel
        _model_type = "hnsw model"
    else
        _model_type = "unknown model"
    end
    printstyled(io, "-[$_embs_type]-[$_model_type] ")
    printstyled(io, "$(description(srcher))", color=:normal)
    printstyled(io, ", $(length(srcher.search_data[:data])) embedded documents")
end

# Function that returns a similar matrix with
# a last column of zeros
function add_final_zeros(a::A) where A<:AbstractMatrix
    m, n = size(a)
    new_a = similar(a, (m,n+1))
    new_a[1:m,1:n] = a
    new_a[:,n+1] .= 0.0
    return new_a::A
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
    # Pre-process documents
    documents = preprocess(documents,
                           TEXT_STRIP_FLAGS,
                           isstemmed=!sconf.stem_words)
    documents_meta = preprocess(documents_meta,
                                METADATA_STRIP_FLAGS,
                                isstemmed=!sconf.stem_words)
    # Build document and document metadata corpora
    # Note: the metadata is kept as well for the purpose of
    #       converying information regarding what is being
    #       searched. The only use for it is when displaying
    #       results
    # TODO: Make storing the metadata optional (some application
    #       may not need it but only the document index)
    crps = build_corpus(documents,
                        DEFAULT_DOCUMENT_TYPE,
                        metadata_vector)
    crps_meta = build_corpus(documents_meta,
                             DEFAULT_DOCUMENT_TYPE,
                             metadata_vector)
    # Update lexicons
    update_lexicon!(crps)
    update_lexicon!(crps_meta)
    # Classic searcher
    if sconf.search == :classic
        # Calculate term importances
        dtm = DocumentTermMatrix(crps)
        dtm_meta = DocumentTermMatrix(crps_meta)
        # Get document importance calculation function
        if sconf.count_type == :tf
            count_func = StringAnalysis.tf
        elseif sconf.count_type == :tfidf
            count_func = StringAnalysis.tf_idf
        else
            @error "Unknown document importance $(sconf.count_type)."
        end
        # No word embeddings
        word_embeddings = nothing
        # Calculate doc importances
        _srchdata = TermCounts(dtm.column_indices,
                               add_final_zeros(count_func(dtm)))
        _srchdata_meta = TermCounts(dtm_meta.column_indices,
                                    add_final_zeros(count_func(dtm_meta)))
    # Semantic searcher
    elseif sconf.search == :semantic
        # Construct element type
        _eltype = eval(sconf.embedding_element_type)
        # Read word embeddings
        if sconf.embeddings_type == :conceptnet
            word_embeddings = load_embeddings(sconf.embeddings_path,
                                              languages=[Languages.English()],
                                              data_type = _eltype)
        elseif sconf.embeddings_type == :word2vec
            word_embeddings = wordvectors(sconf.embeddings_path, _eltype,
                                          kind=sconf.word2vec_filetype)
        else
            @error "$(sconf.embeddings_type) embeddings not supported."
        end
        # Get search model types
        if sconf.embedding_search_model == :naive
            model_type = NaiveEmbeddingModel
        elseif sconf.embedding_search_model == :brutetree
            model_type = BruteTreeEmbeddingModel
        elseif sconf.embedding_search_model == :kdtree
            model_type = KDTreeEmbeddingModel
        elseif sconf.embedding_search_model == :hnsw
            model_type = HNSWEmbeddingModel
        else
            @error "$(sconf.embedding_search_model) embedding model not supported."
        end
        # Construct document data model
        _srchdata = model_type(
            hcat((embed_document(word_embeddings,
                                 crps.lexicon,
                                 doc,
                                 embedding_method=sconf.embedding_method)
                  for doc in documents)...))
        # Construct document metadata model
        _srchdata_meta = model_type(
            hcat((embed_document(word_embeddings,
                                 crps_meta.lexicon,
                                 doc,
                                 embedding_method=sconf.embedding_method)
                  for doc in documents_meta)...))
    else
        # This statement should never be reached in practice
        # as the search option should be checked prior (during parsing)
        @error "Unknown search $(sconf.search)."
    end
    # Build search trees (for suggestions)
    if sconf.search == :classic
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
        crps = Corpus(DEFAULT_DOCUMENT_TYPE[])
    end
    # Build searcher
    srcher = Searcher(sconf,
                      crps,
                      word_embeddings,
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
        where D<:AbstractDocument where E where M<:AbstractSearchData}} = begin
    idxs = Int[]
    for (i, srcher) in enumerate(srchers)
        id(srcher) == an_id && push!(idxs, i)
    end
    return srchers[idxs]
end

getindex(srchers::V, an_id::String) where {V<:Vector{<:Searcher{D,E,M}
        where D<:AbstractDocument where E where M<:AbstractSearchData}} =
    srchers[StringId(an_id)]
