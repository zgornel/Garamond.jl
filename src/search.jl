###############################################
# Search result object and associated methods #
###############################################

# Search results for a Corpus
struct CorpusSearchResult{T<:Real}
    matches::MultiDict{T, TextAnalysis.DocumentMetadata}  # Dict(score=>metadata)
    suggestions::MultiDict{String, String}
end

CorpusSearchResult() = CorpusSearchResult(
    MultiDict{Float64, TextAnalysis.DocumentMetadata}(),
    MultiDict{String, String}()
)

# Calculate the length of a MultiDict as the number
# of values considering all keys
valength(md::MultiDict) = begin
    if isempty(md)
        return 0
    else
        return mapreduce(x->length(x[2]), +, md)
    end
end
    
show(io::IO, csr::CorpusSearchResult) = begin
    nm = valength(csr.matches)
    ns = length(csr.suggestions)
    printstyled(io, "$nm search csr(s)")
    ch = ifelse(nm==0, ".", ":"); printstyled("$ch\n")
    for score in sort(collect(keys(csr.matches)), rev=true)
        for metadata in csr.matches[score]
            printstyled(io, "  $score ~ ", color=:normal, bold=true)
            printstyled(io, "$metadata\n", color=:normal)
        end
    end
    ns > 0 && printstyled(io, "$ns suggestion(s):\n")
    for (keyword, suggestions) in csr.suggestions
        printstyled(io, "  \"$keyword\": ", color=:normal, bold=true)
        printstyled(io, "$(join(suggestions, ", "))\n", color=:normal)
    end
end

isempty(csr::CorpusSearchResult) = isempty(csr.matches) &&
                                   isempty(csr.suggestions)



# Search results for multiple Corpus-like objects (i.e. Corpora)
struct CorporaSearchResult{T}
    corpus_results::Dict{UInt, CorpusSearchResult{T}}  # Dict(score=>metadata)
    suggestions::MultiDict{String, String}
end

CorporaSearchResult() = CorporaSearchResult(
    Dict{UInt, CorpusSearchResult{Float64}}(),
    MultiDict{String, String}()
)

show(io::IO, result::CorporaSearchResult) = begin
    nt = mapreduce(x->valength(x[2].matches), +, result.corpus_results)
    printstyled(io, "$nt search results from $(length(result.corpus_results)) Corpora\n")
    ns = length(result.suggestions)
    for (_hash, _result) in result.corpus_results
        nm = valength(_result.matches)
        printstyled(io, "`-[0x$(string(_hash, base=16))] ", color=:cyan)  # hash
        printstyled(io, "$(nm) search result(s)")
        ch = ifelse(nm==0, ".", ":"); printstyled("$ch\n")
        for score in sort(collect(keys(_result.matches)), rev=true)
            for metadata in _result.matches[score]
                printstyled(io, "  $score ~ ", color=:normal, bold=true)
                printstyled(io, "$metadata\n", color=:normal)
            end
        end
    end
    ns > 0 && printstyled(io, "$ns suggestion(s):\n")
    for (keyword, suggestions) in result.suggestions
        printstyled(io, "  \"$keyword\": ", color=:normal, bold=true)
        printstyled(io, "$(join(suggestions, ", "))\n", color=:normal)
    end
end

isempty(csr::CorporaSearchResult) = isempty(csr.corpus_results) &&
                                    isempty(csr.suggestions)

# Push method (useful for inserting Corpus search results
# into Corpora search results)
function push!(csr::CorporaSearchResult{T},
               sr::Pair{UInt, CorpusSearchResult{T}}) where {T<:Real}
    _hash, _result = sr
    push!(csr.corpus_results, _hash=>_result)  # results get pushed after suggestions
    return csr
end

function update_suggestions!(csr::CorporaSearchResult)
    if length(csr.corpus_results) > 1
        # multiple corpora
        mismatches = intersect((keys(_result.suggestions) for _result in values(csr.corpus_results))...)
        for ks in mismatches
            for _result in values(csr.corpus_results)
                if ks in keys(_result.suggestions)
                    push!(csr.suggestions, ks=>_result.suggestions[ks])
                end
            end
            unique!(csr.suggestions[ks])
        end
    else
        # 1 corpus
        for (ks, vs) in collect(values(csr.corpus_results))[1].suggestions
            push!(csr.suggestions, ks=>vs)
        end
    end
    return csr
end



##################
# Search methods #
##################

# Defaults
const DEFAULT_SEARCH_TYPE = :index  # can be :index or :metadata
const DEFAULT_SEARCH_METHOD = :exact  #can be :exact or :regex
const DEFAULT_MAX_MATCHES = 1_000  # maximum number of matches that can be retrned
const DEFAULT_MAX_SUGGESTIONS = 1  # maximum number of overall suggestions
const DEFAULT_MAX_CORPUS_SUGGESTIONS = 1  # maximum number of suggestions for each corpus
const MAX_EDIT_DISTANCE = 2  # maximum edit distance for which to return suggestions
# Remarks:
#  - the configuration searchmethod == :exact with search_type==:metadata is NOT to be used as the metadata
#  contains compound expressions which the exact method cannot match


# Function that searches through several corpora
function search(crpra::AbstractCorpora,
                needles::Vector{String};
                search_type::Symbol=DEFAULT_SEARCH_TYPE,
                search_method::Symbol=DEFAULT_SEARCH_METHOD,
                ignorecase::Bool=true,
                max_matches::Int=DEFAULT_MAX_MATCHES,
                max_suggestions::Int=DEFAULT_MAX_SUGGESTIONS)
    result = CorporaSearchResult()
    for (_hash, crps) in crpra.corpora
        if crpra.enabled[_hash]
            _result = search(crps,
                             needles,
                             search_tree=crpra.search_trees[_hash, search_type],
                             search_type=search_type,
                             search_method=search_method,
                             ignorecase=ignorecase,
                             max_matches=max_matches,
                             max_suggestions=DEFAULT_MAX_CORPUS_SUGGESTIONS)
            push!(result, _hash=>_result)
        end
    end
    !isempty(result) && update_suggestions!(result, max_suggestions)
    return result
end



"""
	search(crps, needles [;kwargs])

Searches for needles (i.e. key terms) in a corpus' metadata, text or both and 
returns the documents that match best the query. The function returns a 
vector of dictionaries representing the metadata of the best matching
documents.

# Arguments
  * `crps::Corpus{T}` is the text corpus
  * `needles::Vector{String}` is a vector of key terms representing the query

# Keyword arguments
  * `search_tree::BKTree{String}` search tree for mismatch suggestions
  * `search_type::Symbol` is the type of the search; can be `:metadata` (default),
     `:index` or `:all`; the options specify that the needles can be found in
     the metadata of the documents of the corpus, their inverse index or both 
     respectively
  * `search_method::Symbol` controls the type of matching: `:exact` (default)
     searches for the very same string while `:regex` searches for a string
     in the corpus that includes the needle
  * `ignorecase::Bool` specifies whether to ignore the case
  * `max_matches::Int` is the maximum number of search results to return
  * `max_suggestions::Int` is the maximum number of suggestions to return for
     each missing needle

# Examples
```
	...
```
"""
# Function that searches in a corpus'a metdata or metadata + content for needles (i.e. keyterms) 
function search(crps::Corpus{T}, 
                needles::Vector{String};
                search_tree::BKTree{String}=BKTree{String}(),
                search_type::Symbol=:metadata,
                search_method::Symbol=:exact,
                ignorecase::Bool=true,
                max_matches::Int=10,
                max_suggestions::Int=DEFAULT_MAX_CORPUS_SUGGESTIONS) where {T<:AbstractDocument}
    # Checks
    @assert search_type in [:index, :metadata, :all]
    @assert search_method in [:exact, :regex]
    # Initializations
    n = length(crps)		# Number of documents
    p = length(needles)		# Number of search terms
    matches = spzeros(Int, n, p)	# Match matrix
	# Search
    if search_type == :metadata
        matches += search_metadata(crps,
                                   needles,
                                   search_method=search_method,
                                   metadata_fields=metadata_fields,
                                   ignorecase=ignorecase)
    elseif search_type == :index
        matches += search_index(crps,
                                needles,
                                search_method=search_method,
                                ignorecase=ignorecase)
    elseif search_type == :all
        matches +=  search_metadata(crps,
                                    needles,
                                    search_method=search_method,
                                    metadata_fields=metadata_fields,
                                    ignorecase=ignorecase)
        matches += search_index(crps,
                                needles,
                                search_method=search_method,
                                ignorecase=ignorecase)
    else
		@error "FATAL: Unknown search method."
    end
    # Number of needles matched in each document (for sorting search quality)
    needle_matches = vec(sum(matches, dims=2))
    # Number of documents matching each needle (for heuristics)
    doc_matches = vec(sum(matches, dims=1))
    # Try to find closest string
    suggestions = search_heuristically(search_tree,
                                       needles[doc_matches .== 0],
                                       max_suggestions=max_suggestions)
    idxs::Vector{Int} = setdiff(sortperm(needle_matches, rev=true),
                                findall(iszero,needle_matches))
    matches = MultiDict{Float64,TextAnalysis.DocumentMetadata}(
        [needle_matches[idx]=>metadata(crps[idx])
         for (i, idx) in enumerate(idxs)
         if i <= min(max_matches, length(idxs))]
    )
    return CorpusSearchResult(matches, suggestions)
end



"""
    Return a needle expression mutator and an matching function
"""
function parse_search_method(search_method::Symbol)
    if search_method == :exact
        return identity, isequal
    elseif search_method == :regex
        return (arg)->Regex(arg), occursin
    else
        # default if wrong input
        return identity, isequal
    end
end



"""
	Search function for searching in the metadata of the documents in a corpus.
"""
function search_metadata(crps::Corpus{T},
                         needles::Vector{String};
                         search_method::Symbol=:exact,
                         metadata_fields::Vector{Symbol}=Symbol[],
                         ignorecase::Bool=true) where {T<:AbstractDocument}
    # Initializations
    n = length(crps)
    p = length(needles)
    matches = spzeros(Float64, n, p)
    haystack_mutator = ifelse(ignorecase, lowercase, identity)
    needle_mutator, matching_function = parse_search_method(search_method)
    patterns = needle_mutator.(needles)
    # Search
    for (j, pattern) in enumerate(patterns)
        for (i, meta) in enumerate(metadata(crps))
            for field in metadata_fields
                if matching_function(pattern, haystack_mutator(getfield(meta, field)))
                    matches[i,j]+= 1.0
                    break # from 'for field...'
                end
            end
        end
    end
    return matches
end



"""
	Search function for searching in the inverse index of a corpus.
"""
function search_index(crps::Corpus{T},
                      needles::Vector{String};
                      search_method::Symbol=:exact,
                      ignorecase::Bool=true) where {T<:AbstractDocument}
    # Initializations
    n = length(crps)
    p = length(needles)
    matches = spzeros(Float64, n, p)
    invidx = inverse_index(crps)
    haystack_mutator = ifelse(ignorecase, lowercase, identity)
    needle_mutator, matching_function = parse_search_method(search_method)
    patterns = needle_mutator.(needles)
    # Check that inverse index exists
    @assert !isempty(inverse_index(crps)) "FATAL: The corpus has no inverse index."
    # Search
    for (j, pattern) in enumerate(patterns)
        for k in keys(invidx)
            if matching_function(pattern, haystack_mutator(k))
                matches[invidx[k], j].+= 1.0
            end
        end
    end
    return matches 
end



"""
    Search in the search tree for matches.
"""
function search_heuristically(search_tree::BKTree{String},
                              needles::Vector{String};
                              max_suggestions::Int=1)
    # Checks
    @assert !BKTrees.is_empty_node(search_tree.roo) "FATAL: empty search tree."
    # Initializations
    suggestions = MultiDict{String, Vector{Tuple{String, Float64}}}()
    use_heuristic = max_suggestions > 0

    if use_heuristic
        if isempty(needles)
            return suggestions
        else  # there are terms that have not been found
            for needle in needles
                _suggestion_vector = find(search_tree, needle, max_suggestions,
                                          k=MAX_EDIT_DISTANCE)
                push!(suggestions, needle => sort!(_suggestion_vector,
                                                   by=x->x[1]))
        end
    end
    return suggestions
end
