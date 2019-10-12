#=
Ranking API
-----------
The ranker is present in the `SearchEnv` i.e. search environment object.
In order to become usable by the `rank` function, ranker function signatures
should be of the form:

    some_ranker(idxs, request; scores=nothing, environment=nothing)

where:
    `some_ranker` is the name of the ranker
    `indxs` is a list of data indices pertinent to `environment.id_key`
    `request` is the ranking request, containing all needed parameters
    `scores=nothing` if not empty, indicates the scores associated to the
                     data indices
    `environment` a named tuple with at least two fields
        ⋅ `dbdata` - an `IndexedTable` or `NDSparse` object containint the data
        ⋅ `id_key` - the name of the data primary key
        ⋅ `ranker` - the ranking function

The arguments above should be enough to implement any ranker.
=#
rank(env::SearchEnv, request; results=nothing) = begin
    environment = (dbdata=env.dbdata, id_key=env.id_key, ranker=env.ranker)
    if results == nothing
        return rank_from_request(environment, request)
    else
        return rank_from_results(environment, request, results)
    end
end


function rank_from_request(env, request)
    result_id = make_id(StringId, nothing)
    ids = strip.(split(request.query))
    unranked_idxs = db_select_idxs_from_values(env.dbdata,
                                               ids,
                                               request.request_id_key;
                                               id_key=env.id_key)
    ### Call ranker
    ranked_idxs = env.ranker(unranked_idxs, request, environment=env)
    ###
    ranked_result = build_result_from_ids(env.dbdata,
                                          ranked_idxs,
                                          env.id_key,
                                          result_id,
                                          id_key=env.id_key,
                                          max_matches=request.max_matches,
                                          linear_scoring=true)  #::SearchResult
    return [ranked_result]
end


function rank_from_results(env, request, results)
    ranked_results = similar(results)
    for i in eachindex(results)
        unranked_idxs = map(t->t[2], results[i].query_matches)
        scores = map(t->t[1], results[i].query_matches)
        ### Call ranker
        ranked_idxs = env.ranker(unranked_idxs, request; environment=env, scores=scores)
        ###
        ranked_results[i] = build_result_from_ids(env.dbdata,
                                                  ranked_idxs,
                                                  env.id_key,
                                                  results[i].id;
                                                  id_key=env.id_key,
                                                  max_matches=request.max_matches,
                                                  linear_scoring=true)  #::SearchResult
    end
    return ranked_results
end
