#=
Recommendation API
-----------
TODO(Corneliu): Draft this
=#
function recommend(env::SearchEnv, request)
    if env.recommender !== search_recommender
        # Generic recommender, does not need full environment i.e. strip indexes
        env = (dbdata=env.dbdata,
               id_key=env.id_key,
               ranker=env.ranker)
    end
    env.recommender(request; environment=env)
end
