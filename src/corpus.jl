#########################
# Interface for Corpora #
#########################

# Corpus ID (identifies a Corpus and associated structures)
abstract type AbstractID end

struct HashID <: AbstractID
    id::UInt
end

show(io::IO, id::HashID) = print(io, "id=0x$(string(id.id, base=16))")
#print(io::IO, id::HashID) = print(io, "id=0x$(string(id.id, base=16))")
#println(io::IO, id::HashID) = println(io, "id=0x$(string(id.id, base=16))")



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
abstract type AbstractCorpora end

mutable struct Corpora{T} <: AbstractCorpora
    corpus::Dict{T, Corpus}      # hash=>corpus
    enabled::Dict{T, Bool}       # whether to use the corpus in search or not
    refs::Dict{T, CorpusRef}     # Dict(hash=>corpus name)
    index::Dict{T, Dict{String, Vector{Int}}}  # document data inverse index
    index_meta::Dict{T, Dict{String, Vector{Int}}}  # metadata inverse index
    search_trees::Dict{T, Dict{Symbol, BKTree{String}}}  # search trees
end

Corpora{T}() where T<:AbstractID = 
    Corpora(Dict{T, Corpus}(),
            Dict{T, Bool}(),
            Dict{T, CorpusRef}(),
            Dict{T, Dict{String, Vector{Int}}}(),
            Dict{T, Dict{String, Vector{Int}}}(),
            Dict{T, Dict{Symbol, BKTree{String}}}())

Corpora() = Corpora{HashID}()


show(io::IO, crpra::Corpora) = begin
    printstyled(io, "$(length(crpra.corpus))-element Corpora:\n")
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
getindex(crpra::Corpora{T}, key::T) where T<:AbstractID =
    Corpora{T}((getfield(crpra, field)[key] for field in fieldnames(Corpora))...)

getindex(crpra::Corpora{T}, key::UInt) where T<:HashID =
    Corpora{T}((getfield(crpra, field)[T(key)] for field in fieldnames(Corpora))...)

delete!(crpra::Corpora{T}, key::T) where T<:AbstractID = begin
    for field in fieldnames(Corpora)
        delete!(getfield(crpra, field), key)
    end
    return crpra
end

disable!(crpra::Corpora{T}, key::T) where T<:AbstractID = begin
    crpra.enabled[key] = false
    crpra.refs[key].enabled = false
    return crpra
end

disable!(crpra::Corpora{T}) where T<:AbstractID = begin
    for key in keys(crpra)
        disable!(crpra, key)
    end
    return crpra
end

enable!(crpra::Corpora{T}, key::T) where T<:AbstractID = begin
    crpra.enabled[key] = true
    crpra.refs[key].enabled = true
    return crpra
end

enable!(crpra::Corpora{T}) where T<:AbstractID = begin
    for key in keys(crpra)
        enable!(crpra, key)
    end
    return crpra
end

keys(crpra::Corpora{T}) where T<:AbstractID = keys(crpra.corpus)

values(crpra::Corpora{T}) where T<:AbstractID =
    ((crpra.corpus[k], crpra.refs[k], crpra.enabled[k]) for k in keys(crpra.corpus))

update_lexicon!(crpra::Corpora{T}) where T<:AbstractID = begin
    for c in values(crpra.corpus)
        TextAnalysis.update_lexicon!(c)
    end
end

update_inverse_index!(crpra::Corpora{T}) where T<:AbstractID = begin
    for c in values(crpra.corpus)
        TextAnalysis.update_inverse_index!(c)
    end
end



# Load corpora using a Garamond corpora config file
function load_corpora(filename::AbstractString)
	corpus_refs = parse_corpora_configuration(filename)
	load_corpora(corpus_refs)
end

# Load corpora using a vector of corpus references
function load_corpora(crefs::Vector{CorpusRef})
    crpra = Corpora()
    for cref in crefs
        add_corpus!(crpra, cref)  # load and add corpus
    end
    add_search_trees!(crpra, :all)  # add both metadata and index trees
	return crpra
end



# Load corpora using a single corpus reference
function add_corpus!(crpra::Corpora{T}, cref::CorpusRef) where T<:AbstractID
    # Parse file
    crps, index, index_meta = cref.parser(cref.path)
    # Calculate hash
    _hash = HashID(hash(hash(abspath(cref.path))+
                        hash(cref.name)))
    # Update Corpora fields
    push!(crpra.corpus, _hash=>crps)
    push!(crpra.enabled, _hash=>cref.enabled) # all corpora enabled by default
    push!(crpra.refs, _hash=>cref)
    push!(crpra.index, _hash=>index)
    push!(crpra.index_meta, _hash=>index_meta)
	return crpra
end



function add_search_trees!(crpra::Corpora{T},
                           search_type::Symbol;
                           heuristic::Symbol=DEFAULT_HEURISTIC) where T<:AbstractID
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
            words = collect(keys(crpra.index[_hash]))
            push!(crpra.search_trees[_hash],
                  :index=>BKTree((x,y)->evaluate(distance, x, y), words))
        end
        if search_type != :index
            words = collect(keys(crpra.index_meta[_hash]))
            push!(crpra.search_trees[_hash],
                  :metadata=>BKTree((x,y)->evaluate(distance, x, y), words))
        end
    end
    return crpra
end
