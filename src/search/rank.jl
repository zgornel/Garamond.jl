#=
Ranking API
-----------
The ranker is present in the `SearchEnv` i.e. search environment object.
Ranking is performed by calling:

    rank(env, request [; results=nothing]
where:
    `env::SearchEnv` is the search environment object
    `request::InternalRequest` is the request
    `results::Union{Nothing, SearchResult}` are search results; if `nothing`,
        ranking if performed on the IDs present in the query of the request;
        otherwise, the results are re-ranked.


The ranker function signatures (`env.ranker`) should be of the form:

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
function rank(env::SearchEnv, request; results=nothing)
    rankenv = (dbdata=env.dbdata, id_key=env.id_key, ranker=env.ranker)
    __rank(rankenv, request, results)
end


function __rank(env, request, ::Nothing)
    result_id = make_id(StringId, nothing)
    ids = strip.(split(request.query))
    unranked_idxs = db_select_idxs_from_values(env.dbdata,
                                               ids,
                                               request.request_id_key;
                                               id_key=env.id_key)
    ### Call ranker
    ranked_idxs = env.ranker(unranked_idxs, request; scores=nothing, environment=env)
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


function __rank(env, request, results)
    ranked_results = similar(results)
    for i in eachindex(results)
        unranked_idxs = map(t->t[2], results[i].query_matches)
        scores = map(t->t[1], results[i].query_matches)
        ### Call ranker
        ranked_idxs = env.ranker(unranked_idxs, request; scores=scores, environment=env)
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
