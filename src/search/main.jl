function search(env::SearchEnv, request; exclude=nothing, rerank=nothing)

    # Parse query content
    parsed_query = parse_query(request.query, db_schema(env.dbdata))

    issearch = !isempty(parsed_query.search)
    isfilter = !isempty(parsed_query.filter)
    if !isfilter
        # No filter, search always done
        results = search(env.searchers,
                         parsed_query.search,
                         search_method=request.search_method,
                         max_matches=request.max_matches,
                         max_suggestions=request.max_suggestions,
                         custom_weights=request.custom_weights)
    elseif !issearch
        # Filter, no search
        # TODO(Corneliu) id_key should be read from config
        filtered_ids = indexfilter(env.dbdata,
                                   parsed_query.filter,
                                   id_key=DEFAULT_DB_ID_KEY,
                                   exclude=exclude)
        results = search_result_from_indexes(filtered_ids, env.searchers[1].config.id_aggregation,
                                             env.searchers[1].config.vectors_eltype)
    elseif issearch
        # Filter and search
        results = search(env.searchers,
                         parsed_query.search,
                         search_method=request.search_method,
                         max_matches=request.max_matches,
                         max_suggestions=request.max_suggestions,
                         custom_weights=request.custom_weights)
        filtered_ids = indexfilter(env.dbdata,
                                   parsed_query.filter,
                                   id_key=DEFAULT_DB_ID_KEY,
                                   exclude=exclude)
        # Merge results of the two
        #TODO(corneliu) Improve this!!! (i.e.e change result format etc.)
        for r in results
            empty_scores=[]
            for (score, matches) in r.query_matches
                intersect!(matches, filtered_ids)
                isempty(matches) && delete!(r.query_matches, score)
            end
        end
    end

    # Rerank if the case
    rerank!(rerank, results)

    return results
end
