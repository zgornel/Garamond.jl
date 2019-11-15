"""
    Search environment object. It contains all the data, searchers
    and additional structures needed by the engine to function.
"""
mutable struct SearchEnv
    #TODO(Corneliu) Make search environment parametric with respect to
    #               the type of Float being used
    dbdata        #::Union{AbstractNDSparse, AbstractIndexedTable}
    id_key        #::Symbol
    searchers     #::Vector{<:Searcher}
    config_path   #::String
end


"""
    build_search_env(filepath)

Creates a search environment using the information provided by `filepath`.
"""
function build_search_env(filepath)
    # Parse configuration
    env_config = parse_configuration(filepath)

    # Load data
    dbdata = env_config.data_loader()
    db_check_id_key(dbdata, env_config.id_key)

    # Build searchers
    srchers = [build_searcher(dbdata, srcher_config; id_key=env_config.id_key)
               for srcher_config in env_config.searcher_configs]

    # Build search environment
    SearchEnv(dbdata,
              env_config.id_key,
              srchers,
              env_config.config_path)
end


"""
    build_data_env(env::SearchEnv)

Strips searchers from `env`.
"""
build_data_env(env::SearchEnv) = (dbdata=env.dbdata, id_key=env.id_key, config_path=env.config_path)
