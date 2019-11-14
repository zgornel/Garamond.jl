#=
    Ranking API
    -----------

Ranking is performed by calling:

    rank(env, request, results)

where:
    `env::SearchEnv` is the search environment object
    `request::InternalRequest` is the request
    `results::Union{Nothing, SearchResult}` are search results; if `nothing`,
        ranking if performed on the IDs present in the query of the request;
        otherwise, the results are re-ranked.


The ranker function signatures should be of the form:

    some_ranker(idxs, request; scores=nothing, environment=nothing)

where:
    `some_ranker` is the name of the ranker
    `indxs` is a list of data indices pertinent to `environment.id_key`
    `request` is the ranking request, containing all needed parameters
    `scores=nothing` if not empty, indicates the scores associated to the
                     data indices
    `environment` a named tuple with at least two fields
        • `dbdata` - an `IndexedTable` or `NDSparse` object containint the data
        • `id_key` - the name of the data primary key

The arguments above should be enough to implement any ranker.
=#


# Corresponds to ouside rank request
# (IDs specified explicitly in request)
function rank(env::SearchEnv, request, ::Nothing)
    result_id = make_id(StringId, nothing)
    # Extract IDss to be ranked
    ids = strip.(split(request.query))
    unranked_idxs = db_select_idxs_from_values(env.dbdata,
                                               ids,
                                               request.request_id_key;
                                               id_key=env.id_key)
    ### Call ranker
    ranker = safe_symbol_eval(request.ranker, DEFAULT_RANKER_NAME)
    rankenv = (dbdata=env.dbdata, id_key=env.id_key)
    ranked_idxs, _  = ranker(unranked_idxs, nothing, request; environment=rankenv)  # scores are not useful
    ###
    ranked_result = build_result_from_ids(env.dbdata,
                                          ranked_idxs,
                                          env.id_key,
                                          result_id;
                                          id_key=env.id_key,
                                          max_matches=length(ranked_idxs),
                                          linear_scoring=true)  #::SearchResult
    return [ranked_result]
end


# Corresponds to ranking of search/recommendation request
# (IDs specified implicitly in results)
function rank(env::SearchEnv, request, results::Vector{SearchResult{T}}) where {T}
    ranked_results = similar(results)
    ranker = safe_symbol_eval(request.ranker, DEFAULT_RANKER_NAME)
    rankenv = build_data_env(env)
    for i in eachindex(results)
        scores, unranked_idxs = unzip(results[i].query_matches; ndims=2)
        ### Call ranker
        ranked_idxs::Vector{Int}, ranked_scores::Vector{T} =
            ranker(unranked_idxs, scores, request; environment=rankenv)
        ###
        ranked_results[i] = SearchResult(results[i].id,
                                         collect(zip(ranked_scores, ranked_idxs)),
                                         results[i].needle_matches,
                                         results[i].suggestions,
                                         results[i].score_weight)
    end
    return ranked_results
end
