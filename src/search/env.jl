"""
    Search environment object. It contains all the data, searchers
    and additional structures needed by the engine to function.
"""
mutable struct SearchEnv
    dbdata      # Union{AbstractNDSparse, AbstractIndexedTable}
    id_key      # Symbol
    fieldmaps   # Dict{Symbol,Symbol}
    searchers   # Vector{<:Searcher}
    ranker      # Function
end


"""
    build_search_env(filepath)

Creates a search environment using the information provided by `filepath`.
"""
function build_search_env(filepath)
    # Parse configuration
    env_config = parse_configuration(filepath)

    # Load data
    #TODO(Corneliu) Review this i.e. fieldmaps should be removed (with removal of METADATA)
    dbdata, fieldmaps = env_config.data_loader(env_config.data_path)
    check_id_key(dbdata, env_config.id_key)

    # Build searchers
    srchers = [build_searcher(dbdata, fieldmaps, config) for config in env_config.searcher_configs]

    # Build search environment
    SearchEnv(dbdata, env_config.id_key, fieldmaps, srchers, env_config.ranker)
end
