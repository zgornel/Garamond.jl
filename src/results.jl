#################################################
# Search results objects and associated methods #
#################################################

# Search results from a single corpus
struct SearchResult{T<:AbstractFloat}
    id::StringId
    query_matches::MultiDict{T, Int}  # score => document indices
    needle_matches::Dict{String, T}  # needle => sum of scores
    suggestions::MultiDict{String, Tuple{T,String}} # needle => tuples of (score,partial match)
end


isempty(result::T) where T<:SearchResult =
    all(isempty(getfield(result, field)) for field in fieldnames(T))


# Calculate the length of a MultiDict as the number
# of values considering all keys
valength(md::MultiDict) = begin
    if isempty(md)
        return 0
    else
        return mapreduce(x->length(x[2]), +, md)
    end
end


# Show method
show(io::IO, result::SearchResult) = begin
    n = valength(result.query_matches)
    nm = length(result.needle_matches)
    ns = length(result.suggestions)
    printstyled(io, "Search results for $(result.id): ")
    printstyled(io, " $n hits, $nm query terms, $ns suggestions.", bold=true)
end


# Pretty printer of results
function print_search_results(io::IO, srcher::AbstractSearcher, result::SearchResult)
    nm = valength(result.query_matches)
    ns = length(result.suggestions)
    @assert id(srcher) == result.id "Searcher and result id's do not match."
    printstyled(io, "[$(id(srcher))] $nm search results")
    ch = ifelse(nm==0, ".", ":"); printstyled(io, "$ch\n")
    for score in sort(collect(keys(result.query_matches)), rev=true)
        if isempty(srcher.corpus)
            printstyled(io, "*** Corpus data is missing ***", color=:normal)
        else
            for doc in (srcher.corpus[i] for i in result.query_matches[score])
                printstyled(io, "  $score ~ ", color=:normal, bold=true)
                printstyled(io, "$(metadata(doc))\n", color=:normal)
            end
        end
    end
    ns > 0 && printstyled(io, "$ns suggestions:\n")
    for (keyword, suggestions) in result.suggestions
        printstyled(io, "  \"$keyword\": ", color=:normal, bold=true)
        printstyled(io, "$(join(map(x->x[2], suggestions), ", "))\n", color=:normal)
    end
end

print_search_results(srcher::AbstractSearcher, result::SearchResult) =
    print_search_results(stdout, srcher, result)


# Pretty printer of results
function print_search_results(io::IO, srchers::S, results::T;
                              max_suggestions=MAX_CORPUS_SUGGESTIONS
                             ) where {S<:AbstractVector{<:AbstractSearcher},
                                      T<:AbstractVector{<:SearchResult}}
    if !isempty(results)
        nt = mapreduce(x->valength(x.query_matches), +, results)
    else
        nt = 0
    end
    printstyled(io, "$nt search results from $(length(results)) corpora\n")
    for (i, _result) in enumerate(results)
        crps = srchers[i].corpus
        nm = valength(_result.query_matches)
        printstyled(io, "`-[$(_result.id)] ", color=:cyan)  # hash
        printstyled(io, "$(nm) search results")
        ch = ifelse(nm==0, ".", ":"); printstyled(io, "$ch\n")
        if isempty(crps)
            printstyled(io, "*** Corpus data is missing ***\n", color=:normal)
        else
            for score in sort(collect(keys(_result.query_matches)), rev=true)
                for doc in (crps[i] for i in _result.query_matches[score])
                    printstyled(io, "  $score ~ ", color=:normal, bold=true)
                    printstyled(io, "$(metadata(doc))\n", color=:normal)
                end
            end
        end
    end
    suggestions = squash_suggestions(results, max_suggestions)
    ns = length(suggestions)
    ns > 0 && printstyled(io, "$ns suggestions:\n")
    for (keyword, suggest) in suggestions
        printstyled(io, "  \"$keyword\": ", color=:normal, bold=true)
        printstyled(io, "$(join(suggest, ", "))\n", color=:normal)
    end
end

print_search_results(srchers::S, results::T, max_suggestions=MAX_CORPUS_SUGGESTIONS
                    ) where {S<:AbstractVector{<:AbstractSearcher},
                             T<:AbstractVector{<:SearchResult}} =
    print_search_results(stdout,
                         srchers,
                         results,
                         max_suggestions=max_suggestions)


# Squash suggestions for multiple corpora search results
function squash_suggestions(results::Vector{SearchResult},
                            max_suggestions::Int=MAX_SUGGESTIONS)
    suggestions = MultiDict{String, String}()
    # Quickly exit if no suggestions are sought
    max_suggestions <=0 && return suggestions
    if length(results) > 1
        # Results from multiple corpora, suggestions have to
        # be processed somewhat:
        #  - keep only needles not found across all corpora
        #  - remove suggestions that correspond to found needles

        # Get the needles not found across all corpus results
        matched_needles = (needle for _result in results
                           for needle in keys(_result.needle_matches))
        missed_needles = union((keys(_result.suggestions)
                                for _result in results)...)
        # Construct suggestions for the whole AggregateSearcher
        for needle in missed_needles
            all_needle_suggestions = Vector{Tuple{AbstractFloat,String}}()
            for _result in results
                if haskey(_result.suggestions, needle) &&
                   !(any(suggestion in matched_needles
                         for (_, suggestion) in _result.suggestions[needle]))
                   # Current key was not found and the suggestions
                   # for it are not found in the matched needles
                   union!(all_needle_suggestions,
                          _result.suggestions[needle])
                end
            end
            if !isempty(all_needle_suggestions)
                sort!(all_needle_suggestions, by=x->x[1])  # sort vector of tuples by distance
                # Keep results with the same distance even if the number is
                # larger than the maximum
                n = min(max_suggestions, length(all_needle_suggestions))
                nn = 0
                d = -1.0
                for (i, (dist, _)) in enumerate(all_needle_suggestions)
                    if i <= n || d == dist
                        d = dist
                        nn = i
                    end
                end
                push!(suggestions,
                      needle=>map(x->x[2], all_needle_suggestions)[1:nn])
            end
        end
    else
        # Results from one corpus, easy situation, just copy the suggestions
        for _result in results
            for (needle, vs) in _result.suggestions
                # vs is a Vector{Tuple{AbstractFloat, String}},
                # sorted by distance i.e. the float
                for v in vs
                    push!(suggestions, needle=>v[2])
                end
            end
        end
    end
    return suggestions
end
