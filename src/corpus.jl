#########################
# Interface for Corpora #
#########################
abstract type AbstractCorpora end

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
    printstyled(io, "Corpus Reference for $(cref.name)\n:")
    _status = ifelse(cref.enabled, "Enabled", "Disabled")
    _status_color = ifelse(cref.enabled, :light_green, :light_black)
    printstyled(io, "`-[$_status] ", color=_status_color)
    printstyled(io, "$(cref.path)\n")
end


# Corpora can be built from a .garamond configuration file or from a vector of CorpusRef's
mutable struct Corpora <: AbstractCorpora	# the 'hash' identifies the corpus
    corpora::Dict{UInt, Corpus}     # Dict(hash=>corpus)
    refs::Dict{UInt, CorpusRef}     # Dict(hash=>corpus name)
    search_trees::Dict{Tuple{UInt,Symbol}, BKTree{String}}
    enabled::Dict{UInt, Bool}       # whether to use the corpus in search or not
end

Corpora() = Corpora(Dict{UInt, Corpus}(),
                    Dict{UInt, CorpusRef}(),
                    Dict{Tuple{UInt,Symbol}, BKTree{String}}(),
                    Dict{UInt, Bool}())

show(io::IO, crpra::Corpora) = begin
    printstyled(io, "$(length(crpra.corpora))-element Corpora:\n")
    for (_hash, crps) in crpra.corpora
        printstyled(io, "`-[0x$(string(_hash, base=16))] ", color=:cyan)  # hash
        _status = ifelse(crpra.enabled[_hash], "Enabled", "Disabled")
        _status_color = ifelse(crpra.enabled[_hash], :light_green, :light_black)
        printstyled(io, "[$_status] ", color=_status_color)
        printstyled(io, "$(crpra.refs[_hash].name)", color=:normal) #corpus name
        printstyled(io, ", $(length(crps)) documents\n") 
    end
end



# Various iterators over parts of a Corpora
getindex(crpra::Corpora, key::UInt) = crpra.corpora[key]

delete!(crpra::Corpora, key::UInt) = delete!(corporar, key)

disable!(crpra::Corpora, key::UInt) = begin
    crpra.enabled[key] = false
    crpra.refs[key].enabled = false
    return crpra
end

disable!(crpra::Corpora) = begin
    for key in keys(crpra)
        disable!(crpra, key)
    end
    return crpra
end

enable!(crpra::Corpora, key::UInt) = begin
    crpra.enabled[key] = true
    crpra.refs[key].enabled = true
    return crpra
end

enable!(crpra::Corpora) = begin
    for key in keys(crpra)
        enable!(crpra, key)
    end
    return crpra
end

keys(crpra::Corpora) = keys(crpra.corpora)

values(crpra::Corpora) = ((crpra.corpora[k], crpra.refs[k], crpra.enabled[k]) for k in keys(crpra.corpora))

update_lexicon!(crpra::Corpora) = for c in values(crpra.corpora)
    TextAnalysis.update_lexicon!(c)
end

update_inverse_index!(crpra::Corpora) = for c in values(crpra.corpora)
    TextAnalysis.update_inverse_index!(c)
end



# Load corpora using a Garamond data config file
function load_corpora(filename::AbstractString)
	corpus_refs = generate_corpus_references(filename)
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
function add_corpus!(crpra::Corpora, cref::CorpusRef)
    crps = cref.parser(cref.path)
    _hash = hash(abspath(cref.path))
    push!(crpra.corpora, _hash=>crps)
    push!(crpra.refs, _hash=>cref)
    push!(crpra.enabled, _hash=>cref.enabled) # all corpora enabled by default
	return crpra
end


# Search tree constants
const DEFAULT_METADATA_FIELDS = [:author, :name]  # Default metadata fields for search
const DEFAULT_HEURISTIC = :levenshtein  #can be :levenshtein or :fuzzy
const HEURISTIC_TO_DISTANCE = Dict(  # heuristic to distance object mapping
    :levenshtein => StringDistances.Levenshtein(),
    :dameraulevenshtein => StringDistances.DamerauLevenshtein(),
    :hamming => StringDistances.Hamming(),
    :jaro => StringDistances.Jaro())



function add_search_trees!(crpra::AbstractCorpora,
                           search_type::Symbol;
                           metadata_fields::Vector{Symbol}=DEFAULT_METADATA_FIELDS,
                           heuristic::Symbol=DEFAULT_HEURISTIC)
    # Checks
    @assert search_type in [:index, :metadata, :all]
    distance = get(HEURISTIC_TO_DISTANCE, heuristic, DEFAULT_HEURISTIC)
    # Create search vocabulary
    words = String[]
    for (_hash, crps) in crpra.corpora
        if search_type != :metadata
            @assert !isempty(inverse_index(crps)) "FATAL: The corpus has no inverse index."
            words = collect(keys(inverse_index(crps)))
            push!(crpra.search_trees, (_hash, search_type)=>
                  BKTree((x,y)->evaluate(distance, x, y), words))
        elseif search_type != :index
            metadata_it = (metastring(meta, metadata_fields)
                           for meta in metadata(crps))
            words = unique(prepare!(join(metadata_it, " "),
                                    METADATA_STRIP_FLAGS));
            push!(crpra.search_trees, (_hash, search_type)=>
                  BKTree((x,y)->evaluate(distance, x, y), words))
        else
            # Do nothing
        end
    end
    return crpra
end
