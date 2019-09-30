"""
    Search environment object. It contains all the data, searchers
    and additional structures needed by the engine to function.
"""
mutable struct SearchEnv
    dbdata
    fieldmaps
    searchers
end


"""
    build_search_env(config_file)

Creates a search environment using the information provided by `config_file`.
"""
function build_search_env(config_file)
    data_loader, data_path, configs = parse_configuration(config_file)
    #TODO(Corneliu) Review this i.e. fieldmaps should be removed (with removal of METADATA)
    dbdata, fieldmaps = data_loader(data_path)
    srchers = [build_searcher(dbdata, fieldmaps, config) for config in configs]  # build searchers
    return SearchEnv(dbdata, fieldmaps, srchers)
end
