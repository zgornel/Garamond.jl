function search(env::SearchEnv, request; exclude=nothing)

    # Parse the input from the request
    parsedinput = parse_input(env, request)
    issearch = !isempty(parsedinput.search)
    isfilter = !isempty(parsedinput.filter)

    if !isfilter
        # No filter, search always done
        results = search(env.searchers,
                         parsedinput.search;
                         search_method=request.search_method,
                         max_matches=request.max_matches,
                         max_suggestions=request.max_suggestions,
                         custom_weights=request.custom_weights)
    elseif !issearch
        # No search, filter only
        idxs_filt = indexfilter(env.dbdata,
                                parsedinput.filter;
                                id_key=env.id_key,
                                exclude=exclude)
        result = build_result_from_ids(env.dbdata,
                                       idxs_filt,
                                       env.id_key,
                                       make_id(StringId, nothing);
                                       id_key=env.id_key,
                                       max_matches=request.max_matches)
        results = [result]
    elseif issearch
        # Search and filter search results
        results = search(env.searchers,
                         parsedinput.search;
                         search_method=request.search_method,
                         max_matches=request.max_matches,
                         max_suggestions=request.max_suggestions,
                         custom_weights=request.custom_weights)
        #TODO(Corneliu) Decide whether to do multiple searches with
        # higher max_matches (needs InternalRequest specification) to
        # match filter
        idxs_filt = indexfilter(env.dbdata,
                                parsedinput.filter;
                                id_key=env.id_key,
                                exclude=exclude)

        # Filter out ids that are not present in the the filtered ids
        for result in results
            filter!(score_idx -> in(score_idx[2], idxs_filt), result.query_matches)
        end
    end

    # Rerank if the case
    if request.rank
        return rank(env, request; results=results)
    else
        return results
    end
end
