#=
Recommendation API
-----------
TODO(Corneliu): Draft this
=#
function recommend(env::SearchEnv, request)
    #TODO(Corneliu): Make the recommender configurable as well
    if hasproperty(env, :recommender)
        recommender = env.recommender
    else
        recommender = search_recommender
    end

    if recommender !== search_recommender
        # Generic recommender, does not need full environment i.e. strip indexes
        env= (dbdata=env.dbdata, id_key=env.id_key, recommender=DEFAULT_RECOMMENDER, ranker=env.ranker)
    end
    recommender(request; environment=env)
end
