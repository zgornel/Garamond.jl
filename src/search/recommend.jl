#=
    Recommendation API
    ------------------

Recommendations are performed by calling:

    recommend(env, request)

where:
    `env::SearchEnv` is the search environment object
    `request::InternalRequest` is the request


The recommender function signatures should be of the form:

    some_recommender(request; environment=nothing)

where:
    `some_recommender` is the name of the recommender
    `request` is the recommendation request, containing all needed parameters
    `environment` a named tuple with at least two fields
        • `dbdata` - an `IndexedTable` or `NDSparse` object containint the data
        • `id_key` - the name of the data primary key
        • `ranker` - the ranking function

The arguments above should be enough to implement any ranker.
=#
function recommend(env::SearchEnv, request)
    recommender = safe_symbol_eval(request.recommender, DEFAULT_RECOMMENDER_NAME)
    if recommender !== search_recommender
        # Generic recommender, does not need full environment i.e. strip indexes
        env = build_data_env(env)
    end
    ## Call recommender
    recommender(request; environment=env)
    ##
end
