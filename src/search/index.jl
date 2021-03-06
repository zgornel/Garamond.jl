"""
	search(srchers, query [;kwargs])

Searches for query (i.e. key terms) in multiple searches and returns
information regarding the documents that match best the query.
The function returns the search results in the form of
a `Vector{SearchResult}`.

# Arguments
  * `srchers::Vector{Searcher}` is the searchers vector
  * `query` the query, can be either a `String` or `Vector{String}`

# Keyword arguments
  * `search_method::Symbol` controls the type of matching: `:exact`
     uses exact matches while `:regex` consideres the needle a regular expression
  * `max_matches::Int` is the maximum number of search results to return
  * `max_suggestions::Int` is the maximum number of suggestions to return for
     each missing needle
  * `custom_weights::Dict{Symbol, Float}` are custom weights for each
     searcher's results used in result aggregation
"""
function search(srchers::Vector{<:AbstractSearcher{T}},
                query;
                search_method=DEFAULT_SEARCH_METHOD,
                max_matches=MAX_MATCHES,
                max_suggestions=MAX_SUGGESTIONS,
                custom_weights=DEFAULT_CUSTOM_WEIGHTS
               ) where {T<:AbstractFloat}
    # Checks
    @assert search_method in [:exact, :regex]
    @assert max_matches >= 0
    @assert max_suggestions >=0

    # Initializations
    n = length(srchers)
    enabled_searchers = [i for i in 1:n if isenabled(srchers[i])]
    n_enabled = length(enabled_searchers)
    queries = fill(query, n)

    # Search
    results = Vector{SearchResult{T}}(undef, n_enabled)
    ###################################################################
    # A `Threads.@threads` statement in front of the for loop here
    # idicates the use of multi-threading. If multi-threading is used,
    # OPENBLAS multi-threading support has to be disabled by using:
    #   `export OPENBLAS_NUM_THREADS=1` in the shell
    # or start julia with:
    #   `env OPENBLAS_NUM_THREADS=1 julia`
    #
    # WARNING: Multi-theading support (as of v1.1 is still EXPERIMENTAL)
    #          and floating point operations are not thread-safe!
    #          Do not use with semantic search!!
    ###################################################################
    ### Threads.@threads for i in 1:n_enabled
    for i in 1:n_enabled
        results[i] = search(srchers[enabled_searchers[i]],
                            queries[enabled_searchers[i]],
                            search_method=search_method,
                            max_matches=max_matches,
                            max_suggestions=max_suggestions)
    end
    # Aggregate results
    ids_agg = String[srcher.config.id_aggregation for srcher in srchers if isenabled(srcher)]
    aggregate!(results,
               ids_agg,
               method=RESULT_AGGREGATION_STRATEGY,
               max_matches=max_matches,
               max_suggestions=max_suggestions,
               custom_weights=custom_weights)

    # Return results
    return results
end


"""
	search(srcher, query [;kwargs])

Searches for query (i.e. key terms) in `srcher`, and returns information
regarding the the documents that match best the query. The function
returns an object of type `SearchResult`.

# Arguments
  * `srcher::Searcher` is the searcher
  * `query` the query, can be either a `String` or `Vector{String}`

# Keyword arguments
  * `search_method::Symbol` controls the type of matching: `:exact`
     uses exact matches while `:regex` consideres the needle a regular expression
  * `max_matches::Int` is the maximum number of search results to return
  * `max_suggestions::Int` is the maximum number of suggestions to return for
     each missing needle
"""
function search(srcher::Searcher{T,E,I},
                query;  # can be either a string or vector of strings
                search_method::Symbol=DEFAULT_SEARCH_METHOD,
                max_matches::Int=MAX_MATCHES,
                max_suggestions::Int=MAX_SUGGESTIONS
               ) where {T<:AbstractFloat, E, I<:AbstractIndex}
    # Make an entry i.e.e NamedTuple out of the query
    qentry = (query=query2string(query),)  # query treated as single sentence
    qfields = [:query]
    isregex = search_method === :regex
    qembedding, status = embed(srcher.input_embedder[], [qentry]; fields=qfields, isregex=isregex)

    # Search (if document vector is not zero)
    scores, idxs = T[], Int[]
    if first(status)
        idxs, scores = knn_search(srcher.index,
                                  firstcol(qembedding),
                                  min(length(srcher.index), max_matches))  # k
        score_transform!(scores, alpha=srcher.config.score_alpha)
    end
    query_matches = collect(zip(scores, idxs))

    # Find matching and missing needles
    needles = query2vector(query)
    needle_matches, missed_needles = missing_needles(srcher.input_embedder[], needles)

    # Get suggestions
    suggestions = MultiDict{String, Tuple{T, String}}()
    if max_suggestions > 0 && !isempty(missed_needles)
        suggestion_search!(suggestions,
                           srcher.search_trees,
                           missed_needles,
                           max_suggestions=max_suggestions)
    end
    return SearchResult(id(srcher), query_matches, needle_matches,
                        suggestions, srcher.config.score_weight)
end


"""
Returns found and missing needles using an embedder
"""
missing_needles

missing_needles(embedder::WordVectorsEmbedder, needles) = (String[], String[])

missing_needles(embedder::DTVEmbedder, needles) =
    missing_needles(embedder.model, needles)

missing_needles(model::StringAnalysis.RPModel, needles) = begin
    needle_matches = [needle for needle in needles if in(needle, model.vocab)]
    missed_needles = setdiff(needles, needle_matches)
    return needle_matches, missed_needles
end

missing_needles(model::StringAnalysis.LSAModel, needles) = (String[], String[])


"""
    suggestion_search!(suggestions, search_tree, needles [;max_suggestions=1])

Searches in the search tree for partial matches for each of  the `needles`.
"""
function suggestion_search!(suggestions::MultiDict{String, Tuple{T, String}},
                            search_tree::BKTree{String},
                            needles::Vector{S};
                            max_suggestions::Int=1
                           ) where {S<:AbstractString, T<:AbstractFloat}
    if isempty(needles)
        return suggestions
    elseif BKTrees.is_empty_node(search_tree.root)
        @debug "Suggestion tree is empty, no suggestions will be added."
        return suggestions
    else  # there are terms that have not been found
        for needle in needles
            _suggestions = sort!(find(search_tree, String(needle),
                                      MAX_EDIT_DISTANCE,
                                      k=max_suggestions),
                                 by=t->t[1])
            if !isempty(_suggestions)
                n = min(max_suggestions, length(_suggestions))
                push!(suggestions, needle=>_suggestions[1:n])
            end
        end
    end
    return suggestions
end


# Post-processing score function:
#   - map distances [0, Inf) --> [1, 0)
#TODO(Corneliu) Analylically/empirically adapt alpha do vector dimensionality
function score_transform!(x::AbstractVector{T};
                          alpha::T=T(DEFAULT_SCORE_ALPHA),
                          normalize=false) where {T<:AbstractFloat}
    n = length(x)
    @inbounds @simd for i in 1:n
        x[i] = 1 - tanh(alpha * x[i])
    end
    if normalize
        # Forces the scores to spread in the whole
        # interval between 0 and 1
        xmax = maximum(x)
        xmin = minimum(x)
        return (x.-xmin)./(xmax-xmin)
    else
        return x
    end
end


# Useful functions
query2string(query::AbstractString) = String(query)

query2string(query::Vector{String}) = join(query, " ")

query2string(query) = throw(ArgumentError("query2string requires `String` or Vector{String} inputs."))

query2vector(query::Vector{String}) = query

query2vector(query::AbstractString) = String.(tokenize(query, method=DEFAULT_TOKENIZER))

query2vector(query) = throw(ArgumentError("query2vector requires `String` or Vector{String} inputs."))
