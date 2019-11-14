function noop_recommender(request; environment=nothing)
    @debug "Noop recommender, returning empty result..."
    environment == nothing && @error "No search environment provided for noop recommender."
    empty_recommendation = build_result_from_ids(environment.dbdata,
                                                 Int[],
                                                 environment.id_key,
                                                 make_id(StringId, nothing);
                                                 id_key=environment.id_key,
                                                 max_matches=request.max_matches)
    return [empty_recommendation]
end
