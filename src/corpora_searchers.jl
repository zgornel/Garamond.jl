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
make_id(::Type{StringId}, id::T) where T<:Number = StringId(String(id))

const DEFAULT_ID_TYPE = StringId



#############
# CorpusRef #
#############
# CorpusRefs can be built from a data configuration file or manually
mutable struct CorpusRef{T<:AbstractId}
    path::String        # file/directory path (depends on what the parser accepts)
    name::String        # name of corpus
    id::T
    parser::Function    # file/directory parser function used to obtain corpus
    termimp::Symbol     # term importance type i.e. :tf, :tfidf etc
    heuristic::Symbol   # search heuristic for recommendtations
    enabled::Bool       # whether to use the corpus in search or not
end


# Small function that returns 2 empty corpora
_fake_parser(args...) = begin
    crps = Corpus(DEFAULT_DOC_TYPE(""))
    return crps, crps
end


CorpusRef(;path="",
          name="",
          id=random_id(DEFAULT_ID_TYPE),
          parser=_fake_parser,
          termimp=DEFAULT_TERM_IMPORTANCE,
          heuristic=DEFAULT_HEURISTIC,
          enabled=false) =
    CorpusRef(path, name, id, parser, termimp, heuristic, enabled)


Base.show(io::IO, cref::CorpusRef) = begin
    printstyled(io, "$(typeof(cref)) for $(cref.name)\n")
    _status = ifelse(cref.enabled, "Enabled", "Disabled")
    _status_color = ifelse(cref.enabled, :light_green, :light_black)
    printstyled(io, "`-[$_status] ", color=_status_color)
    printstyled(io, "$(cref.path)\n")
end



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
# Interface for CorpusSearcher #
#################################
mutable struct CorpusSearcher{T<:AbstractId,
                              D<:AbstractDocument} <: AbstractSearcher
    id::T
    corpus::Corpus{D}
    enabled::Bool
    ref::CorpusRef
    index::Dict{Symbol, Dict{String, Vector{Int}}}
    term_importances::Dict{Symbol, TermImportances}
    search_trees::Dict{Symbol, BKTree{String}}
end


show(io::IO, corpus_searcher::CorpusSearcher) = begin
    printstyled(io, "$(typeof(corpus_searcher)), ")
    printstyled(io, "[$(corpus_searcher.id)] ", color=:cyan)
    _status = ifelse(corpus_searcher.enabled, "Enabled", "Disabled")
    _status_color = ifelse(corpus_searcher.enabled, :light_green, :light_black)
    printstyled(io, "[$_status] ", color=_status_color)
    printstyled(io, "$(corpus_searcher.ref.name)", color=:normal)
    printstyled(io, ", $(length(corpus_searcher.corpus)) documents\n")
end



#################################
# Interface for CorporaSearcher #
#################################
mutable struct CorporaSearcher{T<:AbstractId, D<:AbstractDocument}
    searchers::Vector{CorpusSearcher{T,D}}
    idmap::Dict{T, Int}
end


show(io::IO, corpora_searcher::CorporaSearcher) = begin
    printstyled(io, "$(length(corpora_searcher.searchers))-element CorporaSearcher:\n")
    for (id, idx) in corpora_searcher.idmap
        print(io, "`-", corpora_searcher.searchers[idx])
    end
end


# Indexing
getindex(corpora_searcher::CorporaSearcher{T,D}, id::T) where
        {T<:AbstractId, D<:AbstractDocument} =
    return corpora_searcher.searchers[corpora_searcher.idmap[id]]

getindex(corpora_searcher::CorporaSearcher{T,D}, id::UInt) where
        {T<:HashId, D<:AbstractDocument} =
    corpora_searcher[HashId(id)]

getindex(corpora_searcher::CorporaSearcher{T,D}, id::String) where
        {T<:StringId, D<:AbstractDocument} =
    corpora_searcher[StringId(id)]


delete!(corpora_searcher::CorporaSearcher{T,D}, id::T) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    deleteat!(corpora_searcher.searchers, corpora_searcher.idmap[id])
    delete!(corpora_searcher.idmap, id)
    return corpora_searcher
end


delete!(corpora_searcher::CorporaSearcher{T,D}, id::Union{String, UInt}) where
        {T<:AbstractId, D<:AbstractDocument} =
    delete!(corpora_searcher, T(id))


disable!(corpora_searcher::CorporaSearcher{T,D}, id::T) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    corpora_searcher[id].enabled = false
    corpora_searcher[id].ref.enabled = false
    return corpora_searcher
end


disable!(corpora_searcher::CorporaSearcher{T,D}, id::Union{String, UInt}) where
        {T<:AbstractId, D<:AbstractDocument} =
    disable!(corpora_searcher, T(id))


disable!(corpora_searcher::CorporaSearcher{T,D}) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    for id in keys(corpora_searcher.idmap)
        disable!(corpora_searcher, id)
    end
    return corpora_searcher
end


enable!(corpora_searcher::CorporaSearcher{T,D}, id::T) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    corpora_searcher[id].enabled = true
    corpora_searcher[id].ref.enabled = true
    return corpora_searcher
end


enable!(corpora_searcher::CorporaSearcher{T,D}, id::Union{String, UInt}) where
        {T<:AbstractId, D<:AbstractDocument} =
    enable!(corpora_searcher, T(id))


enable!(corpora_searcher::CorporaSearcher{T,D}) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    for id in keys(corpora_searcher.idmap)
        enable!(corpora_searcher, id)
    end
    return corpora_searcher
end



# Construct corpora searchers using a Garamond corpora config file
function corpora_searchers(filename::AbstractString)
	crefs = parse_corpora_configuration(filename)
	corpora_searchers(crefs)
end


# Construct corpora searchers using a vector of corpus references
function corpora_searchers(crefs::Vector{CorpusRef{T}};
                           doc_type::Type{D}=DEFAULT_DOC_TYPE) where
        {T<:AbstractId, D<:AbstractDocument}
    n = length(crefs)
    crpra_searcher = CorporaSearcher(Vector{CorpusSearcher{T,D}}(undef, n),
                                     Dict{T,Int}())
    for (i, cref) in enumerate(crefs)
        crpra_searcher.searchers[i] = corpus_searcher(cref)
        push!(crpra_searcher.idmap, cref.id=>i)
    end
	return crpra_searcher
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
Adds a CorpusSearcher to a CorporaSearcher using a CorpusRef.
```
function corpus_searcher(cref::R) where R<:CorpusRef
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
    # Initialize CorpusSearcher
    cs = CorpusSearcher(id,
                        crps,
                        cref.enabled,
                        cref,
                        Dict{Symbol, Dict{String, Vector{Int}}}(),
                        Dict{Symbol, TermImportances}(),
                        Dict{Symbol, BKTree{String}}())
    # Update CorpusSearcher
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
    # Add CorpusSearcher to CorporaSearcher
    return cs
end
