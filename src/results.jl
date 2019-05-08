#################################################
# Search results objects and associated methods #
#################################################
"""
    Object that stores the search results from a single searcher.
"""
struct SearchResult{T<:AbstractFloat}
    id::StringId
    query_matches::MultiDict{T, Int}  # score => document indices
    needle_matches::Vector{String}
    suggestions::MultiDict{String, Tuple{T,String}} # needle => tuples of (score,partial match)
    score_weight::T
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


"""
    Aggregates search results from several searchers based on
their `aggregation_id` i.e. results from searchers with identical
aggregation id's are merged together into a new search result that
replaces the individual searcher ones.
"""
function aggregate!(results::Vector{S},
                    aggregation_ids::Vector{StringId};
                    method::Symbol=RESULT_AGGREGATION_STRATEGY,
                    max_matches::Int=MAX_MATCHES,
                    max_suggestions::Int=MAX_SUGGESTIONS,
                    custom_weights::Dict{String, Float64}=DEFAULT_CUSTOM_WEIGHTS
                   ) where S<:SearchResult{T} where T
    if !(method in [:minimum, :maximum, :median, :product, :mean])
        @warn "Unknown aggregation strategy :$method. " *
              "Defaulting to $RESULT_AGGREGATION_STRATEGY."
        method = RESULT_AGGREGATION_STRATEGY
    end
    # If all aggregation ids are different (i.e. no aggregation)
    # return results unchanged
    uids  = unique(aggregation_ids)
    length(uids) == length(aggregation_ids) && return results

    # Some aggregation ids are identical (i.e. aggregate)
    for uid in uids
        positions = findall(x->x==uid, aggregation_ids)
        if length(positions) > 1
            target_results = results[positions]
            # aggregate
            qm = [result.query_matches for result in target_results]
            weights = [T(result.score_weight * get(custom_weights, result.id.id, 1.0))
                       for result in target_results]
            merged_query_matches = _aggregate(qm, weights,
                                              method=method,
                                              max_matches=max_matches)
            # Create SearchResult object
            agg_result = SearchResult(
                uid,
                merged_query_matches,
                unique(vcat((result.needle_matches for result in target_results)...)),
                squash_suggestions(target_results, max_suggestions),
                one(T))
            # replace first occurence that has the non-unique id_aggregation
            results[positions[1]] = agg_result
            # remove other occurences (these have been merged)
            deleteat!(results, positions[2:end])
            deleteat!(aggregation_ids, positions[2:end])
        end
    end
end


function _aggregate(query_matches::Vector{MultiDict{T,Int}},
                    weights::Vector{T};
                    method::Symbol=RESULT_AGGREGATION_STRATEGY,
                    max_matches::Int=DEFAULT_MAX_MATCHES,
                   ) where T<:AbstractFloat
    # Preprocess data
    row = 0
    doc2row = Dict{Int,Int}()
    rowcol2score = Dict{Tuple{Int,Int},T}()
    for (col, qm) in enumerate(query_matches)
        for (score, doc_idxs) in qm
            for doc in doc_idxs
                if !(doc in keys(doc2row))
                    row += 1
                    push!(doc2row, doc=>row)
                    push!(rowcol2score, (row, col)=>score)
                else
                    push!(rowcol2score, (doc2row[doc], col)=>score)
                end
            end
        end
    end
    # build matrix with scores for all documents from all searchers
    m, n = length(doc2row), length(query_matches)
    scores = zeros(T, m, n)
    @inbounds for ((row, col), score) in rowcol2score
        scores[row, col] = weights[col] * score
    end
    # merge results
    final_scores::Vector{T} = zeros(T, m)
    (method == :minimum) && (final_scores = minimum(scores, dims=2)[:,1])
    (method == :maximum) && (final_scores = maximum(scores, dims=2)[:,1])
    (method == :median) && (final_scores = median(scores, dims=2)[:,1])
    (method == :product) && (final_scores = prod(scores, dims=2)[:,1])
    (method == :mean) && (final_scores = mean(scores, dims=2)[:,1])

    row2doc = Dict(v=>k for (k,v) in doc2row)
    # Sort and trim result list
    idxs = sortperm(final_scores, rev=true)[1:min(m, max_matches)]
    return MultiDict(zip(final_scores[idxs], [row2doc[i] for i in idxs]))
end


# Squash suggestions for multiple corpora search results
function squash_suggestions(results::Vector{SearchResult{T}},
                            max_suggestions::Int=MAX_SUGGESTIONS
                           ) where T<:AbstractFloat
    suggestions = MultiDict{String, Tuple{T,String}}()
    # Quickly exit if no suggestions are sought
    max_suggestions <=0 && return suggestions
    if length(results) > 1
        # Results from multiple corpora, suggestions have to
        # be processed somewhat:
        #  - keep only needles not found across all corpora
        #  - remove suggestions that correspond to found needles

        # Get the needles not found across all corpus results
        matched_needles = (needle for _result in results
                           for needle in _result.needle_matches)
        missed_needles = union((keys(_result.suggestions)
                                for _result in results)...)
        # Construct suggestions for the whole AggregateSearcher
        for needle in missed_needles
            all_needle_suggestions = Vector{Tuple{T,String}}()
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
                push!(suggestions, needle=>all_needle_suggestions[1:nn])
            end
        end
    elseif length(results) == 1
        # Results from one corpus, easy situation, just copy the suggestions
        suggestions = results[1].suggestions
    end
    return suggestions
end


# Pretty printer of results
function print_search_results(io::IO, srcher, result)
    nm = valength(result.query_matches)
    ns = length(result.suggestions)
    @assert id(srcher) == result.id "Searcher and result id's do not match."
    printstyled(io, "[$(id(srcher))] ", color=:blue, bold=true)
    printstyled(io, "$(nm) search results", bold=true)
    ch = ifelse(nm==0, ".", ":"); printstyled(io, "$ch\n")
    for score in sort(collect(keys(result.query_matches)), rev=true)
        if isempty(documents(srcher.corpus))
            printstyled(io, "*** Corpus data is missing ***",
                        color=:red, bold=true)
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

print_search_results(srcher, result) = print_search_results(stdout, srcher, result)


# Pretty printer of results
function print_search_results(io::IO, srchers::AbstractVector, results::AbstractVector,
                              max_suggestions::Int=MAX_SUGGESTIONS)
    if !isempty(results)
        nt = mapreduce(x->valength(x.query_matches), +, results)
    else
        nt = 0
    end
    # Map searchers and results by id or id_aggregation
    result2srcher = Dict{Int, Int}()
    for (i, _result) in enumerate(results)
        for (j, _srcher) in enumerate(srchers)
            if _result.id == _srcher.config.id ||
                    _result.id == _srcher.config.id_aggregation
                push!(result2srcher, i=>j)
                break
            end
        end
    end
    printstyled(io, "$nt search results from $(length(results)) corpora\n")
    for (i, _result) in enumerate(results)
        crps = srchers[result2srcher[i]].corpus
        nm = valength(_result.query_matches)
        printstyled(io, "`-[$(_result.id)] ", color=:blue, bold=true)
        printstyled(io, "$(nm) search results", bold=true)
        ch = ifelse(nm==0, ".", ":"); printstyled(io, "$ch\n")
        if isempty(crps)
            printstyled(io, "*** Corpus data is missing ***\n",
                        color=:red, bold=true)
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
        printstyled(io, "$(join(map(x->x[2], suggest), ", "))\n", color=:normal)
    end
end

print_search_results(srchers::AbstractVector, results::AbstractVector,
                     max_suggestions=MAX_SUGGESTIONS) =
    print_search_results(stdout, srchers, results, max_suggestions)
