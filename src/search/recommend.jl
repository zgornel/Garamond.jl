#=
Recommendation API
-----------
TODO(Corneliu): Draft this
=#

#TODO(Corneliu): Make the recommender configurable as well
DEFAULT_RECOMMENDER = search_recommender

recommend(env::SearchEnv, request) = begin
    recommendenv = (dbdata=env.dbdata, id_key=env.id_key, recommender=DEFAULT_RECOMMENDER)
    __recommend(recommendenv, request)
end

__recommend(env, request) = env.recommender(dbdata, request; id_key=env.id_key)


function search_recommender(dbdata, request; id_key=DEFAULT_DB_ID_KEY)
    # Generate new  query and overwrite the original one
    request.query, id = generate_query(request.query, dbdata, recommend_id_key=request.request_id_key)

    # Get the linear id of the entry for which recommendations are sought
    target_entry = db_select_entry(dbdata, id, id_key=request.request_id_key)
    linear_id = isempty(target_entry) ? nothing : getproperty(target_entry, env.id_key)

    # Search (end exclude original entry)
    similars = search(env, request; exclude=linear_id)
end
