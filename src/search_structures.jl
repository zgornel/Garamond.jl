#############################
# Term Importance structure #
#############################
struct TermImportances
    column_indices::Dict{String, Int}
    values::SparseMatrixCSC{Float64, Int64}
end


Base.show(io::IO, ti::TermImportances) = begin
    m, n = size(ti.values)
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
    ref::SearchConfig
    index::Dict{Symbol, Dict{String, Vector{Int}}}
    term_importances::Dict{Symbol, TermImportances}
    search_trees::Dict{Symbol, BKTree{String}}
end


show(io::IO, clsrcher::ClassicSearcher) = begin
    printstyled(io, "$(typeof(clsrcher)), ")
    printstyled(io, "[$(clsrcher.id)] ", color=:cyan)
    _status = ifelse(clsrcher.enabled, "Enabled", "Disabled")
    _status_color = ifelse(clsrcher.enabled, :light_green, :light_black)
    printstyled(io, "[$_status] ", color=_status_color)
    printstyled(io, "$(clsrcher.ref.name)", color=:normal)
    printstyled(io, ", $(length(clsrcher.corpus)) documents\n")
end



##################################
# Interface for SemanticSearcher #
##################################

# Searcher structures
mutable struct SemanticSearcher{T<:AbstractId,
                                      D<:AbstractDocument} <: AbstractSearcher
    id::T
    corpus::Corpus{D}
    enabled::Bool
    ref::SearchConfig{T}
    embeddings::Dict{Symbol, Matrix{Float64}}
end

show(io::IO, semsrcher::SemanticSearcher{T,D}) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    printstyled(io, "$(typeof(semsrcher)), ")
    printstyled(io, "[$(semsrcher.id)] ", color=:cyan)
    _status = ifelse(semsrcher.enabled, "Enabled", "Disabled")
    _status_color = ifelse(semsrcher.enabled, :light_green, :light_black)
    printstyled(io, "[$_status] ", color=_status_color)
    printstyled(io, "$(semsrcher.ref.name)", color=:normal)
    printstyled(io, ", $(length(semsrcher.corpus)) documents\n")
end


# Function to create a semantic search structure from corpus refs' similar to corpora_searchers
function semantic_corpora_searchers(filename::AbstractString,
                                    cptnetpath::AbstractString;
                                    languages=[Languages.English()])
    crefs = parse_corpora_configuration(filename)
    cptnet = load_embeddings(cptnetpath, languages=languages)
    semantic_corpora_searchers(crefs, cptnet)
end

function semantic_corpora_searchers(crefs::Vector{SearchConfig{T}},
                                    conceptnet::ConceptNet{L,K,U};
                                    doc_type::Type{D}=DEFAULT_DOC_TYPE) where
        {T<:AbstractId, D<:AbstractDocument, L<:Languages.Language,
         K<:AbstractString, U<:AbstractVector}
    n = length(crefs)
    semantic_corpora_searcher = AggregateSearcher(
        Vector{SemanticSearcher{T,D}}(undef, n), Dict{T,Int}())
    for (i, cref) in enumerate(crefs)
        semantic_corpora_searcher.searchers[i] = sematic_searcher(cref, conceptnet)
        push!(semantic_corpora_searcher.idmap, cref.id=>i)
    end
	return semantic_corpora_searcher
end




###################################
# Interface for AggregateSearcher #
###################################
mutable struct AggregateSearcher{T<:AbstractId, D<:AbstractDocument}
    searchers::Vector{ClassicSearcher{T,D}}
    idmap::Dict{T, Int}
end


show(io::IO, aggsrcher::AggregateSearcher) = begin
    printstyled(io, "$(length(aggsrcher.searchers))-element AggregateSearcher:\n")
    for (id, idx) in aggsrcher.idmap
        print(io, "`-", aggsrcher.searchers[idx])
    end
end


# Indexing
getindex(aggsrcher::AggregateSearcher{T,D}, id::T) where
        {T<:AbstractId, D<:AbstractDocument} =
    return aggsrcher.searchers[aggsrcher.idmap[id]]

getindex(aggsrcher::AggregateSearcher{T,D}, id::UInt) where
        {T<:HashId, D<:AbstractDocument} =
    aggsrcher[HashId(id)]

getindex(aggsrcher::AggregateSearcher{T,D}, id::String) where
        {T<:StringId, D<:AbstractDocument} =
    aggsrcher[StringId(id)]


delete!(aggsrcher::AggregateSearcher{T,D}, id::T) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    deleteat!(aggsrcher.searchers, aggsrcher.idmap[id])
    delete!(aggsrcher.idmap, id)
    return aggsrcher
end


delete!(aggsrcher::AggregateSearcher{T,D}, id::Union{String, UInt}) where
        {T<:AbstractId, D<:AbstractDocument} =
    delete!(aggsrcher, T(id))


disable!(aggsrcher::AggregateSearcher{T,D}, id::T) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    aggsrcher[id].enabled = false
    aggsrcher[id].ref.enabled = false
    return aggsrcher
end


disable!(aggsrcher::AggregateSearcher{T,D}, id::Union{String, UInt}) where
        {T<:AbstractId, D<:AbstractDocument} =
    disable!(aggsrcher, T(id))


disable!(aggsrcher::AggregateSearcher{T,D}) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    for id in keys(aggsrcher.idmap)
        disable!(aggsrcher, id)
    end
    return aggsrcher
end


enable!(aggsrcher::AggregateSearcher{T,D}, id::T) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    aggsrcher[id].enabled = true
    aggsrcher[id].ref.enabled = true
    return aggsrcher
end


enable!(aggsrcher::AggregateSearcher{T,D}, id::Union{String, UInt}) where
        {T<:AbstractId, D<:AbstractDocument} =
    enable!(aggsrcher, T(id))


enable!(aggsrcher::AggregateSearcher{T,D}) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    for id in keys(aggsrcher.idmap)
        enable!(aggsrcher, id)
    end
    return aggsrcher
end



# Construct corpora searchers using a Garamond corpora config file
function aggregate_searcher(filename::AbstractString)
	crefs = parse_corpora_configuration(filename)
	aggregate_searcher(crefs)
end


# Construct corpora searchers using a vector of corpus references
function aggregate_searcher(crefs::Vector{SearchConfig{T}};
                           doc_type::Type{D}=DEFAULT_DOC_TYPE) where
        {T<:AbstractId, D<:AbstractDocument}
    n = length(crefs)
    aggsrcher = AggregateSearcher(Vector{ClassicSearcher{T,D}}(undef, n),
                                     Dict{T,Int}())
    for (i, cref) in enumerate(crefs)
        aggsrcher.searchers[i] = classic_searcher(cref)
        push!(aggsrcher.idmap, cref.id=>i)
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


```
Adds a ClassicSearcher to a AggregateSearcher using a SearchConfig.
```
function classic_searcher(cref::R) where R<:SearchConfig
    # Parse file
    crps, crps_meta = cref.parser(cref.path)
    # get id
    id = cref.id
    # Prepare
    prepare!(crps, TEXT_STRIP_FLAGS)
    prepare!(crps_meta, METADATA_STRIP_FLAGS)
    # Update lexicons
    update_lexicon!(crps)
    update_lexicon!(crps_meta)
    # Update inverse indices
    update_inverse_index!(crps)
    update_inverse_index!(crps_meta)
    # Calculate term importances
    dtm = DocumentTermMatrix(crps)
    dtm_meta = DocumentTermMatrix(crps_meta)
    # Get document importance calculation function
    if cref.termimp == :tf
        imp_func = TextAnalysis.tf
    elseif cref.termimp == :tfidf
        imp_func = TextAnalysis.tf_idf
    else
        @warn "Unknown document importance :$(cref.termimp); defaulting to frequency."
    end
    # Calculate doc importances
    term_imp = TermImportances(dtm.column_indices, add_final_zeros(imp_func(dtm)))
    term_imp_meta = TermImportances(dtm_meta.column_indices, add_final_zeros(imp_func(dtm_meta)))
    # Initialize ClassicSearcher
    cs = ClassicSearcher(id,
                        crps,
                        cref.enabled,
                        cref,
                        Dict{Symbol, Dict{String, Vector{Int}}}(),
                        Dict{Symbol, TermImportances}(),
                        Dict{Symbol, BKTree{String}}())
    # Update ClassicSearcher
    push!(cs.index, :index=>crps.inverse_index)
    push!(cs.index, :metadata=>crps_meta.inverse_index)
    push!(cs.term_importances, :index=>term_imp)
    push!(cs.term_importances, :metadata=>term_imp_meta)
    distance = get(HEURISTIC_TO_DISTANCE, cref.heuristic, DEFAULT_DISTANCE)
    push!(cs.search_trees, :index=>BKTree((x,y)->evaluate(distance, x, y),
                                           collect(keys(crps.inverse_index))
                                          ))
    push!(cs.search_trees, :metadata=>BKTree((x,y)->evaluate(distance, x, y),
                                              collect(keys(crps_meta.inverse_index))
                                             ))
    # Add ClassicSearcher to AggregateSearcher
    return cs
end



function sematic_searcher(cref, conceptnet::ConceptNet{L,K,U}) where
        {L<:Languages.Language, K<:AbstractString, U<:AbstractVector}
    # Parse file
    crps, crps_meta = cref.parser(cref.path)
    # Prepare
    prepare!(crps, TEXT_STRIP_FLAGS)
    prepare!(crps_meta, METADATA_STRIP_FLAGS)
    ### # Update lexicons
    update_lexicon!(crps)
    update_lexicon!(crps_meta)
    ### # Update inverse indices
    ### update_inverse_index!(crps)
    ### update_inverse_index!(crps_meta)

    scs = SemanticSearcher(cref.id,
                                 crps,
                                 cref.enabled,
                                 cref,
                                 Dict{Symbol, Matrix{Float64}}())
    # Update SemanticSearcher
    push!(scs.embeddings, :index=>hcat((get_document_embedding(
                                            conceptnet, crps.lexicon, doc)
                                        for doc in crps)...))
    push!(scs.embeddings, :metadata=>hcat((get_document_embedding(
                                                conceptnet, crps_meta.lexicon, doc)
                                           for doc in crps_meta)...))
    return scs
end
