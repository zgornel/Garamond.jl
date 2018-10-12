#########################
# Interface for Corpora #
#########################

# Corpus ID (identifies a Corpus and associated structures)
struct HashId <: AbstractId
    id::UInt
end

show(io::IO, id::HashId) = print(io, "id=0x$(string(id.id, base=16))")
#print(io::IO, id::HashId) = print(io, "id=0x$(string(id.id, base=16))")
#println(io::IO, id::HashId) = println(io, "id=0x$(string(id.id, base=16))")



# CorpusRefs can be built from a data configuration file or manually
mutable struct CorpusRef
    path::String        # file/directory path
    name::String        # name of corpus
    parser::Function    # file/directory parser function used to obtain corpus
    enabled::Bool       # whether to use the corpus in search or not
end

CorpusRef(;path="", name="", parser=identity, enabled=false) =
    CorpusRef(path, name, parser, enabled)

Base.show(io::IO, cref::CorpusRef) = begin
    printstyled(io, "Corpus Reference for $(cref.name)\n")
    _status = ifelse(cref.enabled, "Enabled", "Disabled")
    _status_color = ifelse(cref.enabled, :light_green, :light_black)
    printstyled(io, "`-[$_status] ", color=_status_color)
    printstyled(io, "$(cref.path)\n")
end



# Corpora can be built from a .garamond configuration file or from a vector of CorpusRef's
mutable struct Corpora{T,D} <: AbstractCorpora
    corpus::Dict{T, Corpus{D}}   # hash=>corpus
    enabled::Dict{T, Bool}       # whether to use the corpus in search or not
    refs::Dict{T, CorpusRef}     # Dict(hash=>corpus name)
    index::Dict{T, Dict{Symbol, Dict{String, Vector{Int}}}}  # document and metadata inverse index
    search_trees::Dict{T, Dict{Symbol, BKTree{String}}}  # search trees
end

Corpora{T,D}() where {T<:AbstractId, D<:AbstractDocument} =
    Corpora(Dict{T, Corpus{D}}(),
            Dict{T, Bool}(),
            Dict{T, CorpusRef}(),
            Dict{T, Dict{Symbol, Dict{String, Vector{Int}}}}(),
            Dict{T, Dict{Symbol, BKTree{String}}}()
           )

# Some useful constants
const DEFAULT_ID_TYPE = HashId
const DEFAULT_DOC_TYPE = TextAnalysis.NGramDocument

Corpora{T}() where T<:AbstractId = Corpora{T, DEFAULT_DOC_TYPE}()

Corpora{D}() where D<:AbstractDocument = Corpora{DEFAULT_ID_TYPE, D}()

Corpora() = Corpora{DEFAULT_ID_TYPE, DEFAULT_DOC_TYPE}()


show(io::IO, crpra::Corpora{T,D}) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    printstyled(io, "$(length(crpra.corpus))-element Corpora{$T,$D}:\n")
    for (_hash, crps) in crpra.corpus
        printstyled(io, "`-[$_hash] ", color=:cyan)  # hash
        _status = ifelse(crpra.enabled[_hash], "Enabled", "Disabled")
        _status_color = ifelse(crpra.enabled[_hash], :light_green, :light_black)
        printstyled(io, "[$_status] ", color=_status_color)
        printstyled(io, "$(crpra.refs[_hash].name)", color=:normal) #corpus name
        printstyled(io, ", $(length(crps)) documents\n") 
    end
end



# Various iterators over parts of a Corpora
getindex(crpra::Corpora{T,D}, key::T) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    new_crpra = Corpora{T,D}()
    for field in fieldnames(Corpora)
        setfield!(new_crpra, field, Dict(key=>getfield(crpra, field)[key]))
    end
    return new_crpra
end

getindex(crpra::Corpora{T,D}, key::UInt) where
        {T<:AbstractId, D<:AbstractDocument} =
    crpra[HashId(key)]

delete!(crpra::Corpora{T,D}, key::T) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    for field in fieldnames(Corpora)
        delete!(getfield(crpra, field), key)
    end
    return crpra
end

disable!(crpra::Corpora{T,D}, key::T) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    crpra.enabled[key] = false
    crpra.refs[key].enabled = false
    return crpra
end

disable!(crpra::Corpora{T,D}) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    for key in keys(crpra)
        disable!(crpra, key)
    end
    return crpra
end

enable!(crpra::Corpora{T,D}, key::T) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    crpra.enabled[key] = true
    crpra.refs[key].enabled = true
    return crpra
end

enable!(crpra::Corpora{T,D}) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    for key in keys(crpra)
        enable!(crpra, key)
    end
    return crpra
end

keys(crpra::Corpora{T,D}) where {T<:AbstractId, D<:AbstractDocument} =
    keys(crpra.corpus)

values(crpra::Corpora{T,D}) where {T<:AbstractId, D<:AbstractDocument} =
    ((crpra.corpus[k],
      crpra.enabled[k],
      crpra.refs[k],
      crpra.index[k],
      crpra.index_meta[k],
      crpra.search_trees[k]) for k in keys(crpra))



# Load corpora using a Garamond corpora config file
function load_corpora(filename::AbstractString)
	corpus_refs = parse_corpora_configuration(filename)
	load_corpora(corpus_refs)
end

# Load corpora using a vector of corpus references
function load_corpora(crefs::Vector{CorpusRef};
                      id_type::Type{T}=DEFAULT_ID_TYPE,
                      doc_type::Type{D}=DEFAULT_DOC_TYPE) where
        {T<:AbstractId, D<:AbstractDocument}
    crpra = Corpora{T,D}()
    for cref in crefs
        add_corpus!(crpra, cref)  # load and add corpus
    end
    add_search_trees!(crpra, :all)  # add both metadata and index trees
	return crpra
end



# Load corpora using a single corpus reference
function add_corpus!(crpra::Corpora{T,D}, cref::CorpusRef) where
        {T<:AbstractId, D<:AbstractDocument}
    # Parse file
    crps, index, index_meta = cref.parser(cref.path)
    # Calculate hash
    _hash = HashId(hash(hash(abspath(cref.path))+
                        hash(cref.name)))
    # Update Corpora fields
    push!(crpra.corpus, _hash=>crps)
    push!(crpra.enabled, _hash=>cref.enabled) # all corpora enabled by default
    push!(crpra.refs, _hash=>cref)
    push!(crpra.index, _hash=>Dict{Symbol, Dict{String,Vector{Int}}}())
    push!(crpra.index[_hash], :index=>index)
    push!(crpra.index[_hash], :metadata=>index_meta)
	return crpra
end



function add_search_trees!(crpra::Corpora{T,D},
                           search_type::Symbol;
                           heuristic::Symbol=DEFAULT_HEURISTIC) where
        {T<:AbstractId, D<:AbstractDocument}
    # Checks
    @assert search_type in [:index, :metadata, :all]
    distance = get(HEURISTIC_TO_DISTANCE, heuristic, DEFAULT_DISTANCE)
    # Create search vocabulary
    words = String[]
    for _hash in keys(crpra.corpus)
        # Add an empty entry
        push!(crpra.search_trees, _hash=>Dict{Symbol, BKTree{String}}())
        # Construct and push relevant trees
        if search_type != :metadata
            words = collect(keys(crpra.index[_hash][:index]))
            push!(crpra.search_trees[_hash],
                  :index=>BKTree((x,y)->evaluate(distance, x, y), words))
        end
        if search_type != :index
            words = collect(keys(crpra.index[_hash][:metadata]))
            push!(crpra.search_trees[_hash],
                  :metadata=>BKTree((x,y)->evaluate(distance, x, y), words))
        end
    end
    return crpra
end
