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
    build_search_env(env_config; cache_path=nothing)

Creates a search environment using the information provided by the
environment configuration `env_config`. A cache filepath can be
specified by `cache_path` in which case the function will attempt to
load it first.
"""
function build_search_env(env_config; cache_path=nothing)
    # Cache has priority over config
    if cache_path != nothing
        try
            env = deserialize(cache_path)
            @info "• Environment successfully loaded (deserialized) from $cache_path."
            return env
        catch e
            @warn "Could not load (deserialize) environment from $cache_path.\n$e"
        end
    end
    try
        # Load data
        dbdata = env_config.data_loader()
        db_check_id_key(dbdata, env_config.id_key)

        # Build searchers
        srchers = [build_searcher(dbdata, srcher_config; id_key=env_config.id_key)
                   for srcher_config in env_config.searcher_configs]

        # Build search environment
        env = SearchEnv(dbdata, env_config.id_key, srchers, env_config.config_path)
        @info "• Environment successfully built using config $(env_config.config_path)."
        return env
    catch e
        @warn "Could not build environment from $(env_config.config_path).\n$e\nExiting..."
        exit()
    end
end


"""
    build_search_env(config_path; cache_path=nothing)

Creates a search environment using the information provided by the
configuration file `config_path`.
"""
build_search_env(config_path::AbstractString; cache_path=nothing) =
    build_search_env(parse_configuration(config_path); cache_path=cache_path)


"""
    build_data_env(env::SearchEnv)

Strips searchers from `env`.
"""
build_data_env(env::SearchEnv) = (dbdata=env.dbdata, id_key=env.id_key, config_path=env.config_path)
