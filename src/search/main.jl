function search(env::SearchEnv,
                request;
                exclude=nothing,
                rerank=env.ranker,
                id_key=DEFAULT_DB_ID_KEY)

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
        # No search, filter only
        filtered_ids = indexfilter(env.dbdata,
                                   parsed_query.filter,
                                   id_key=id_key,
                                   exclude=exclude)
        results = search_result_from_indexes(filtered_ids, make_id(StringId, nothing))
    elseif issearch
        # Search and filter search results
        results = search(env.searchers,
                         parsed_query.search,
                         search_method=request.search_method,
                         max_matches=request.max_matches,
                         max_suggestions=request.max_suggestions,
                         custom_weights=request.custom_weights)
        filtered_ids = indexfilter(env.dbdata,
                                   parsed_query.filter,
                                   id_key=id_key,
                                   exclude=exclude)
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
    rerank(results)
end
