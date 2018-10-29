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
struct TermCounts
    column_indices::Dict{String, Int}
    values::SparseMatrixCSC{Float64, Int64}
end


show(io::IO, tc::TermCounts) = begin
    m, n = size(tc.values)
    print("Term importances for $m documents, $n unique terms.")
end



#################################
# Interface for ClassicSearcher #
#################################
mutable struct ClassicSearcher{T<:AbstractId,
                               D<:AbstractDocument} <: AbstractSearcher
    id::T
    corpus::Corpus{D}
    enabled::Bool
    config::SearchConfig
    term_counts::Dict{Symbol, TermCounts}
    search_trees::Dict{Symbol, BKTree{String}}
end


show(io::IO, clsrcher::ClassicSearcher) = begin
    printstyled(io, "ClassicSearcher, ")
    printstyled(io, "[$(clsrcher.id)] ", color=:cyan)
    _status = ifelse(clsrcher.enabled, "enabled", "disabled")
    _status_color = ifelse(clsrcher.enabled, :light_green, :light_black)
    printstyled(io, "[$_status] ", color=_status_color)
    printstyled(io, "$(clsrcher.config.name)", color=:normal)
    printstyled(io, ", $(size(clsrcher.term_counts[:data].values, 1)) documents\n")
end



######################################
# Word embeddings related structures #
######################################
abstract type AbstractEmbeddingModel end

mutable struct NaiveEmbeddingModel{N<:AbstractFloat}<:AbstractEmbeddingModel
    data::Matrix{N}
end

#TODO (Corneliu): Add kd-trees, hnsw models


##################################
# Interface for SemanticSearcher #
##################################

# Searcher structures
mutable struct SemanticSearcher{T<:AbstractId,
                                D<:AbstractDocument,
                                E,  # can be ConceptNet or WordVectors etc.
                                M<:AbstractEmbeddingModel} <: AbstractSearcher
    id::T
    corpus::Corpus{D}
    enabled::Bool
    config::SearchConfig{T}
    embeddings::E
    model::Dict{Symbol, M}
end

show(io::IO, semsrcher::SemanticSearcher) = begin
    printstyled(io, "SemanticSearcher, ")
    printstyled(io, "[$(semsrcher.id)] ", color=:cyan)
    _status = ifelse(semsrcher.enabled, "enabled", "disabled")
    _status_color = ifelse(semsrcher.enabled, :light_green, :light_black)
    printstyled(io, "[$_status]", color=_status_color)
    # Get embeddings type string
    if semsrcher.embeddings isa WordVectors
        _embs_type = "word2vec"
    elseif semsrcher.embeddings isa ConceptNet
        _embs_type = "conceptnet"
    else
        _embs_type = "unknown embeddings"
    end
    # Get model type string
    if semsrcher.model isa NaiveEmbeddingModel
        _model_type = "naive model"
    else
        _model_type = "unknown model"
    end
    printstyled(io, "-[$_embs_type, $_model_type] ")
    printstyled(io, "$(semsrcher.config.name)", color=:normal)
    printstyled(io, ", $(size(semsrcher.model[:data].data, 2)) embedded documents\n")
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
    aggsrcher = AggregateSearcher(Vector{AbstractSearcher}(undef, n),
                                  Dict{T,Int}())
    for (i, sconf) in enumerate(sconfs)
        if sconf.search == :classic
            aggsrcher.searchers[i] = classic_searcher(sconf)
        else
            aggsrcher.searchers[i] = semantic_searcher(sconf)
        end
        push!(aggsrcher.idmap, sconf.id=>i)
    end
	return aggsrcher
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
Creates a ClassicSearcher from a SearchConfig.
"""
function classic_searcher(sconf::SearchConfig)
    # Parse file
    crps, crps_meta = sconf.parser(sconf.data_path)
    # get id
    id = sconf.id
    # Prepare
    prepare!(crps, TEXT_STRIP_FLAGS)
    prepare!(crps_meta, METADATA_STRIP_FLAGS)
    # Update lexicons
    update_lexicon!(crps)
    update_lexicon!(crps_meta)
    # Calculate term importances
    dtm = DocumentTermMatrix(crps)
    dtm_meta = DocumentTermMatrix(crps_meta)
    # Get document importance calculation function
    if sconf.count_type == :tf
        count_func = TextAnalysis.tf
    elseif sconf.count_type == :tfidf
        count_func = TextAnalysis.tf_idf
    else
        @warn "Unknown document importance :$(sconf.count_type); defaulting to frequency."
    end
    # Calculate doc importances
    term_cnt = TermCounts(dtm.column_indices, add_final_zeros(count_func(dtm)))
    term_cnt_meta = TermCounts(dtm_meta.column_indices, add_final_zeros(count_func(dtm_meta)))
    # Initialize ClassicSearcher
    clsrcher = ClassicSearcher(id,
                               crps,
                               sconf.enabled,
                               sconf,
                               Dict{Symbol, TermCounts}(),
                               Dict{Symbol, BKTree{String}}())
    # Update ClassicSearcher
    push!(clsrcher.term_counts, :data=>term_cnt)
    push!(clsrcher.term_counts, :metadata=>term_cnt_meta)
    distance = get(HEURISTIC_TO_DISTANCE, sconf.heuristic, DEFAULT_DISTANCE)
    push!(clsrcher.search_trees, :data=>BKTree((x,y)->evaluate(distance, x, y),
                                    collect(keys(crps.lexicon))))
    push!(clsrcher.search_trees, :metadata=>BKTree((x,y)->evaluate(distance, x, y),
                                    collect(keys(crps_meta.lexicon))))
    # Add ClassicSearcher to AggregateSearcher
    return clsrcher
end


"""
Creates a ClassicSearcher from a SearchConfig.
"""
function semantic_searcher(sconf::SearchConfig)
    # Parse file
    crps, crps_meta = sconf.parser(sconf.data_path)
    # Prepare
    prepare!(crps, TEXT_STRIP_FLAGS)
    prepare!(crps_meta, METADATA_STRIP_FLAGS)
    ### # Update lexicons
    update_lexicon!(crps)
    update_lexicon!(crps_meta)
    # Read word embeddings
    if sconf.embeddings_type == :conceptnet
        word_embeddings = load_embeddings(sconf.embeddings_path, languages=[Languages.English()])
    elseif sconf.embeddings_type == :word2vec
        word_embeddings = wordvectors(sconf.embeddings_path, kind=:binary)
    else
        @error "$(sconf.embeddings_type) embeddings not yet supported!"
    end
    if sconf.embedding_search_model == :naive
        model_type = NaiveEmbeddingModel
    else
        @error "$(sconf.embedding_search_model) embedding model not yet supported!"
    end
    # Build semantic searcher
    semsrcher = SemanticSearcher(sconf.id,
                                 crps,
                                 sconf.enabled,
                                 sconf,
                                 word_embeddings,
                                 Dict{Symbol, model_type}())
    # Construct document data model
    data_embeddings = hcat(
        (get_document_embedding(word_embeddings, crps.lexicon, doc)
         for doc in crps)...)
    push!(semsrcher.model, :data=>model_type(data_embeddings))
    # Construct document metadata model
    metadata_embeddings = hcat(
        (get_document_embedding(word_embeddings, crps_meta.lexicon, doc)
         for doc in crps_meta)...)
    push!(semsrcher.model, :metadata=>model_type(metadata_embeddings))
    # Return searcher
    return semsrcher
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
    aggsrcher[id].enabled = false
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
    aggsrcher[id].enabled = true
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
