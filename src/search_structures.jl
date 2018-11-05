########################################################
# Corpus Id's i.e. keys that uniquely identify corpora #
########################################################

struct HashId <: AbstractId
    id::UInt
end


struct StringId <: AbstractId
    id::String
end


show(io::IO, id::StringId) = print(io, "id=\"$(id.id)\"")
show(io::IO, id::HashId) = print(io, "id=0x$(string(id.id, base=16))")


random_id(::Type{HashId}) = HashId(hash(rand()))
random_id(::Type{StringId}) = StringId(randstring())


# Construct IDs
make_id(::Type{HashId}, id::String) = HashId(parse(UInt, id))  # the id has to be parsable to UInt
make_id(::Type{HashId}, id::T) where T<:Integer = HashId(UInt(abs(id)))
make_id(::Type{StringId}, id::T) where T<:AbstractString = StringId(String(id))
make_id(::Type{StringId}, id::T) where T<:Number = StringId(string(id))

const DEFAULT_ID_TYPE = StringId



################
# SearchConfig #
################
# SearchConfigs can be built from a data configuration file or manually
mutable struct SearchConfig{I<:AbstractId}
    # general
    id::I                           # searcher/corpus id
    search::Symbol                  # search type i.e. :classic, :semantic
    name::String                    # name of the searcher.corpus
    enabled::Bool                   # whether to use the corpus in search or not
    data_path::String               # file/directory path for the data (depends on what the parser accepts)
    parser::Function                # parser function used to obtain corpus
    # classic search
    count_type::Symbol              # search term counting type i.e. :tf, :tfidf etc (classic search)
    heuristic::Symbol               # search heuristic for recommendtations (classic search)
    # semantic search
    embeddings_path::String         # path to the embeddings file
    embeddings_type::Symbol         # type of the embeddings i.e. :conceptnet, :word2vec (semantic search)
    embedding_method::Symbol        # How to arrive at a single embedding from multiple i.e. :bow, :arora (semantic search)
    embedding_search_model::Symbol  # type of the search model i.e. :naive, :kdtree, :hnsw (semantic search)
end


# Small function that returns 2 empty corpora
_fake_parser(args...) = begin
    crps = Corpus(DEFAULT_DOC_TYPE(""))
    return crps, crps
end


# Keyword argument constructor; all arguments sho
SearchConfig(;
          id=random_id(DEFAULT_ID_TYPE),
          search=DEFAULT_SEARCH,
          name="",
          enabled=false,
          data_path="",
          parser=_fake_parser,
          count_type=DEFAULT_COUNT_TYPE,
          heuristic=DEFAULT_HEURISTIC,
          embeddings_path="",
          embeddings_type=DEFAULT_EMBEDDINGS_TYPE,
          embedding_method=DEFAULT_EMBEDDING_METHOD,
          embedding_search_model=DEFAULT_EMBEDDING_SEARCH_MODEL) =
    # Call normal constructor
    SearchConfig(id, search, name, enabled, data_path, parser,
                 count_type, heuristic,
                 embeddings_path, embeddings_type,
                 embedding_method, embedding_search_model)


Base.show(io::IO, sconf::SearchConfig) = begin
    printstyled(io, "SearchConfig for $(sconf.name)\n")
    _status = ifelse(sconf.enabled, "enabled", "disabled")
    _status_color = ifelse(sconf.enabled, :light_green, :light_black)
    printstyled(io, "`-[$_status]", color=_status_color)
    _search_color = ifelse(sconf.search==:classic, :cyan, :light_cyan)
    printstyled(io, "-[$(sconf.search)] ", color=_search_color)
    printstyled(io, "$(sconf.data_path)\n")
end



###########################
# Term Counting structure #
###########################
abstract type AbstractDocumentCount <: AbstractSearchData
end

struct TermCounts <: AbstractDocumentCount
    column_indices::Dict{String, Int}
    values::SparseMatrixCSC{Float64, Int64}
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
mutable struct Searcher{T<:AbstractId,
                        D<:AbstractDocument,
                        E,
                        M<:AbstractSearchData} <: AbstractSearcher
    config::SearchConfig{T}                     # most of what is not actual data
    corpus::Corpus{D}                           # corpus
    embeddings::E                               # needed to embed query
    search_data::Dict{Symbol, M}                # actual search data (classic and semantic)
    search_trees::Dict{Symbol, BKTree{String}}  # for suggestions
end


# Useful methods
id(srcher::Searcher{T,D,E,M}) where {T,D,E,M} = srcher.config.id::T

name(srcher::Searcher{T,D,E,M}) where {T,D,E,M} = srcher.config.name

isenabled(srcher::Searcher{T,D,E,M}) where {T,D,E,M} = srcher.config.enabled

# Show method
show(io::IO, srcher::Searcher{T,D,E,M}) where {T,D,E,M} = begin
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
    printstyled(io, "$(name(srcher))", color=:normal)
    printstyled(io, ", $(length(srcher.search_data[:data])) embedded documents\n")
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
    searcher(sconf)

Creates a Searcher from a SearchConfig.
"""
function searcher(sconf::SearchConfig{T}) where T
    # Parse file
    crps, crps_meta = sconf.parser(sconf.data_path)
    # Prepare
    prepare!(crps, TEXT_STRIP_FLAGS)
    prepare!(crps_meta, METADATA_STRIP_FLAGS)
    ### # Update lexicons
    update_lexicon!(crps)
    update_lexicon!(crps_meta)
    # Classic search
    if sconf.search == :classic
        # Calculate term importances
        dtm = DocumentTermMatrix(crps)
        dtm_meta = DocumentTermMatrix(crps_meta)
        # Get document importance calculation function
        if sconf.count_type == :tf
            count_func = TextAnalysis.tf
        elseif sconf.count_type == :tfidf
            count_func = TextAnalysis.tf_idf
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
    elseif sconf.search == :semantic
        # Read word embeddings
        if sconf.embeddings_type == :conceptnet
            word_embeddings = load_embeddings(sconf.embeddings_path,
                                              languages=[Languages.English()])
        elseif sconf.embeddings_type == :word2vec
            word_embeddings = wordvectors(sconf.embeddings_path,
                                          kind=:binary)
        else
            @error "$(sconf.embeddings_type) embeddings not supported."
        end
        # Create model
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
            hcat((embed_document(word_embeddings, crps.lexicon, doc,
                                 embedding_method=sconf.embedding_method)
                  for doc in crps)...))
        # Construct document metadata model
        _srchdata_meta = model_type(
            hcat((embed_document(word_embeddings, crps_meta.lexicon, doc,
                                 embedding_method=sconf.embedding_method)
                  for doc in crps_meta)...))
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
    # Build semantic searcher
    srcher = Searcher(sconf,
                      crps,
                      word_embeddings,
                      Dict(:data=>_srchdata, :metadata=>_srchdata_meta),
                      Dict(:data=>_srchtree_data, :metadata=>_srchtree_meta)
                     )
    return srcher
end



###################################
# Interface for AggregateSearcher #
###################################
mutable struct AggregateSearcher{T<:AbstractId, S<:AbstractSearcher}
    searchers::Vector{S}
    idmap::Dict{T, Int}
end


show(io::IO, aggsrcher::AggregateSearcher) = begin
    printstyled(io, "$(length(aggsrcher.searchers))-element AggregateSearcher:\n")
    for (id, idx) in aggsrcher.idmap
        print(io, "`-", aggsrcher.searchers[idx])
    end
end


# Function to create a semantic search structure from corpus configs' similar to corpora_searchers
function aggregate_searcher(data_config_path::AbstractString)
    sconfs = parse_data_config(data_config_path)
    aggregate_searcher(sconfs)
end

function aggregate_searcher(sconfs::Vector{SearchConfig{T}}) where T<:AbstractId
    n = length(sconfs)
    aggsrcher = AggregateSearcher(Vector{Searcher}(undef, n),
                                  Dict{T,Int}())
    for (i, sconf) in enumerate(sconfs)
        aggsrcher.searchers[i] = searcher(sconf)
        push!(aggsrcher.idmap, sconf.id=>i)
    end
	return aggsrcher
end



#################################
# Utils for Aggregate searchers #
#################################
# Indexing
getindex(aggsrcher::AggregateSearcher{T,S}, id::T) where
        {T<:AbstractId, S<:AbstractSearcher} =
    return aggsrcher.searchers[aggsrcher.idmap[id]]

getindex(aggsrcher::AggregateSearcher{T,S}, id::UInt) where
        {T<:HashId, S<:AbstractSearcher} =
    aggsrcher[HashId(id)]

getindex(aggsrcher::AggregateSearcher{T,S}, id::String) where
        {T<:StringId, S<:AbstractSearcher} =
    aggsrcher[StringId(id)]


delete!(aggsrcher::AggregateSearcher{T,S}, id::T) where
        {T<:AbstractId, S<:AbstractSearcher} = begin
    deleteat!(aggsrcher.searchers, aggsrcher.idmap[id])
    delete!(aggsrcher.idmap, id)
    return aggsrcher
end


delete!(aggsrcher::AggregateSearcher{T,S}, id::Union{String, UInt}) where
        {T<:AbstractId, S<:AbstractSearcher} =
    delete!(aggsrcher, T(id))


disable!(aggsrcher::AggregateSearcher{T,S}, id::T) where
        {T<:AbstractId, S<:AbstractSearcher} = begin
    aggsrcher[id].config.enabled = false
    return aggsrcher
end


disable!(aggsrcher::AggregateSearcher{T,S}, id::Union{String, UInt}) where
        {T<:AbstractId, S<:AbstractSearcher} =
    disable!(aggsrcher, T(id))


disable!(aggsrcher::AggregateSearcher{T,S}) where
        {T<:AbstractId, S<:AbstractSearcher} = begin
    for id in keys(aggsrcher.idmap)
        disable!(aggsrcher, id)
    end
    return aggsrcher
end


enable!(aggsrcher::AggregateSearcher{T,S}, id::T) where
        {T<:AbstractId, S<:AbstractSearcher} = begin
    aggsrcher[id].config.enabled = true
    return aggsrcher
end


enable!(aggsrcher::AggregateSearcher{T,S}, id::Union{String, UInt}) where
        {T<:AbstractId, S<:AbstractSearcher} =
    enable!(aggsrcher, T(id))


enable!(aggsrcher::AggregateSearcher{T,S}) where
        {T<:AbstractId, S<:AbstractSearcher} = begin
    for id in keys(aggsrcher.idmap)
        enable!(aggsrcher, id)
    end
    return aggsrcher
end
