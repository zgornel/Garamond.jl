###############################################
# Search result object and associated methods #
###############################################

# Search results for a Corpus
struct CorpusSearchResult{T<:Real}
    matches::MultiDict{T, TextAnalysis.DocumentMetadata}  # score=>metadata
    suggestions::MultiDict{String, Tuple{Float64,String}}
end

CorpusSearchResult() = CorpusSearchResult(
    MultiDict{Float64, TextAnalysis.DocumentMetadata}(),
    MultiDict{String, Tuple{Float64,String}}()
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
    printstyled(io, "$nm search result(s)")
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
        printstyled(io, "$(join(map(x->x[2], suggestions), ", "))\n", color=:normal)
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

# Update suggestions for multiple corpora search results
function update_suggestions!(csr::CorporaSearchResult, max_suggestions::Int=1)
    max_suggestions <=0 && return MultiDict{String, String}()
    if length(csr.corpus_results) > 1
        # multiple corpora
        mismatches = intersect((keys(_result.suggestions)
                                for _result in values(csr.corpus_results))...)
        for ks in mismatches
            _tmpvec = Vector{Tuple{Float64,String}}()
            for _result in values(csr.corpus_results)
                if ks in keys(_result.suggestions)
                    _tmpvec = vcat(_tmpvec, _result.suggestions[ks])
                end
            end
            sort!(_tmpvec, by=x->x[1])  # sort vector of tuples by distance
            n = min(max_suggestions, length(_tmpvec))
            nn = 0
            d = -1.0
            for (i, (dist, _)) in enumerate(_tmpvec)
                if i <= n || d == dist
                    d = dist
                    nn = i
                end
            end
            push!(csr.suggestions, ks=>map(x->x[2],_tmpvec)[1:nn])
        end
    else
        # 1 corpus result
        for (ks, vs) in collect(values(csr.corpus_results))[1].suggestions
            # vs is a Vector{Tuple{Float64, String}},
            # sorted by distance i.e. the float
            for v in vs
                push!(csr.suggestions, ks=>v[2])
            end
        end
    end
    return csr
end



##################
# Search methods #
##################

# Remarks:
#  - the configuration searchmethod == :exact with search_type==:metadata is NOT
#  to be used as the metadata contains compound expressions which the exact method cannot match

# Function that searches through several corpora
function search(crpra::AbstractCorpora,
                needles::Vector{String};
                search_type::Symbol=DEFAULT_SEARCH_TYPE,
                search_method::Symbol=DEFAULT_SEARCH_METHOD,
                max_matches::Int=DEFAULT_MAX_MATCHES,
                max_suggestions::Int=DEFAULT_MAX_SUGGESTIONS,
                max_corpus_suggestions::Int=DEFAULT_MAX_CORPUS_SUGGESTIONS)
    result = CorporaSearchResult()
    n = length(crpra.corpora)
    max_corpus_suggestions = min(max_suggestions, max_corpus_suggestions)
    # Issue warning when search the metadata with exact matches as the
    # metadata contains by definition compound words that are difficult
    # to match exactly
    if search_type == :metadata && search_method == :exact
        @warn "Searching the metadata with exact matches if bound to yield poor results!"
    end
    for (_hash, crps) in crpra.corpora
        if crpra.enabled[_hash]
            _result = search(crps,
                             needles,
                             search_tree=crpra.search_trees[_hash, search_type],
                             search_type=search_type,
                             search_method=search_method,
                             max_matches=max_matches,
                             max_suggestions=max_corpus_suggestions)
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
                metadata_fields::Vector{Symbol}=DEFAULT_METADATA_FIELDS,
                max_matches::Int=10,
                max_suggestions::Int=DEFAULT_MAX_CORPUS_SUGGESTIONS
               ) where {T<:AbstractDocument}
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
                                   metadata_fields=metadata_fields)
    elseif search_type == :index
        matches += search_index(crps,
                                needles,
                                search_method=search_method)
    elseif search_type == :all
        matches +=  search_metadata(crps,
                                    needles,
                                    search_method=search_method,
                                    metadata_fields=metadata_fields)
        matches += search_index(crps,
                                needles,
                                search_method=search_method)
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
    nm = min(max_matches, length(idxs))
    matches = MultiDict{Float64,TextAnalysis.DocumentMetadata}()
    for (i, idx) in enumerate(idxs)
        if i <= nm
            push!(matches, needle_matches[idx]=>metadata(crps[idx]))
        end
    end
    return CorpusSearchResult(matches, suggestions)
end



"""
    Return a needle expression mutator and an matching function
"""
function parse_search_method(search_method::Symbol)
    if search_method == :exact
        return identity, isequal
    elseif search_method == :regex
        return (arg::String)->Regex(arg), occursin
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
                         metadata_fields::Vector{Symbol}=Symbol[]
                        ) where {T<:AbstractDocument}
    # Initializations
    n = length(crps)
    p = length(needles)
    matches = spzeros(Float64, n, p)
    needle_mutator, matching_function = parse_search_method(search_method)
    patterns = needle_mutator.(needles)
    # Search
    for (j, pattern) in enumerate(patterns)
        for (i, meta) in enumerate(metadata(crps))
            for field in metadata_fields
                if matching_function(pattern, getfield(meta, field))
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
                     ) where {T<:AbstractDocument}
    # Initializations
    n = length(crps)
    p = length(needles)
    matches = spzeros(Float64, n, p)
    invidx = inverse_index(crps)
    needle_mutator, matching_function = parse_search_method(search_method)
    patterns = needle_mutator.(needles)
    # Check that inverse index exists
    @assert !isempty(inverse_index(crps)) "FATAL: The corpus has no inverse index."
    # Search
    haystack = (k for k in keys(invidx))
    empty_vector = Int[]
    for (j, pattern) in enumerate(patterns)
        if search_method == :exact
            idxs = get(invidx, pattern, empty_vector) # fast!!
            for i in idxs
                matches[i,j]+= 1.0
            end
        else
            for k in haystack
                if matching_function(pattern, k)
                    for i in invidx[k]
                        matches[i,j]+= 1.0
                    end
                end
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
    @assert !BKTrees.is_empty_node(search_tree.root) "FATAL: empty search tree."
    # Initializations
    suggestions = MultiDict{String, Tuple{Float64, String}}()
    use_heuristic = max_suggestions > 0

    if use_heuristic
        if isempty(needles)
            return suggestions
        else  # there are terms that have not been found
            for needle in needles
                _suggestion_vector = sort!(find(search_tree, needle,
                                                MAX_EDIT_DISTANCE,
                                                k=max_suggestions),
                                           by=x->x[1])
                n = min(max_suggestions, length(_suggestion_vector))
                push!(suggestions, needle=>_suggestion_vector[1:n])
            end
        end
    end
    return suggestions
end
