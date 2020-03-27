"""
    Search environment object. It contains all the data, searchers
    and additional structures needed by the engine to function.
"""
struct SearchEnv{T}
    dbdata        #::Union{AbstractNDSparse, AbstractIndexedTable}
    id_key        #::Symbol
    sampler       #::Function
    embedders::Vector{<:AbstractEmbedder{T}}
    searchers::Vector{<:AbstractSearcher{T}}
    config_path   #::String
end


# Exceptions
struct SearchEnvConsistencyException <: Exception
    msg::String
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
        # Load data and check primary id
        dbdata = env_config.data_loader()
        db_check_id_key(dbdata, env_config.id_key)

        # Build embedders
        embedders = [build_embedder(dbdata,
                                    embdr_config;
                                    vectors_eltype=env_config.vectors_eltype,
                                    id_key=env_config.id_key)
                     for embdr_config in env_config.embedder_configs]

        # Build searchers
        searchers = [build_searcher(dbdata,
                                    embedders,
                                    srcher_config;
                                    id_key=env_config.id_key)
                     for srcher_config in env_config.searcher_configs]

        # Build search environment
        env = SearchEnv(dbdata,
                        env_config.id_key,
                        env_config.data_sampler,
                        embedders,
                        searchers,
                        env_config.config_path)

        @info "• Environment successfully built using config $(env_config.config_path)."
        return env
    catch e
        @warn "Could not build environment from $(env_config.config_path).\n$e"
        return nothing
    end
end


"""
    build_search_env(config_path; cache_path=nothing)

Creates a search environment using the information provided by the
configuration file `config_path`.
"""
build_search_env(config_path::AbstractString; cache_path=nothing) =
    build_search_env(parse_configuration(config_path); cache_path=cache_path)


build_search_env(::Nothing; cache_path=nothing) = nothing


"""
    build_data_env(env::SearchEnv)

Strips searchers from `env`.
"""
build_data_env(env::SearchEnv) = (dbdata=env.dbdata, id_key=env.id_key, config_path=env.config_path)


"""
    push!(env::SearchEnv, rawdata)

Pushes to a search environment i.e. to the db and all indexes.
"""
Base.push!(env::SearchEnv, rawdata) = pushinner!(env, rawdata, :last)


"""
    pushfirst!(env::SearchEnv, rawdata)

Pushes to the first position to a search environment i.e. to the db and all indexes.
"""
Base.pushfirst!(env::SearchEnv, rawdata) = pushinner!(env, rawdata, :first)


function safe_indexes_method_assert(method, env::SearchEnv{T}, args...) where {T}
    if !all(hasmethod(method, Tuple{typeof(srcher.index), args...}) for srcher in env.searchers)
        @warn "Environment modification failed: not all indexes suport method $method."
        return false
    end
    return true
end


# Inner method used for pushing
function pushinner!(env::SearchEnv{T}, rawdata, position::Symbol) where {T}
    index_operation = ifelse(position === :first, pushfirst!, push!)
    srcher_operation = ifelse(position === :first, pushfirst!, push!)
    db_operation = ifelse(position === :first, db_pushfirst!, db_push!)

    !safe_indexes_method_assert(index_operation, env, AbstractVector{T}) &&
        return nothing

    entry = env.sampler(rawdata)
    try
        map(env.searchers) do srcher
            srcher_operation(srcher, entry)
        end
    catch e
        throw(SearchEnvConsistencyException("$e"))
    end
    db_operation(env.dbdata, entry; id_key=env.id_key)
    return nothing
end


"""
    pop!(env::SearchEnv)

Pops last point from a search environment. Returns last db row and associated indexed vector.
"""
Base.pop!(env::SearchEnv) = popinner!(env, :last)


"""
    popfirst!(env::SearchEnv)

Pops first point from a search environment. Returns first db row and associated indexed vector.
"""
Base.popfirst!(env::SearchEnv) = popinner!(env, :first)


# Inner method used for pushing
function popinner!(env::SearchEnv{T}, position::Symbol) where {T}
    index_operation = ifelse(position === :first, popfirst!, pop!)
    srcher_operation = ifelse(position === :first, popfirst!, pop!)
    db_operation = ifelse(position === :first, db_popfirst!, db_pop!)

    !safe_indexes_method_assert(index_operation, env) &&
        return nothing

    popped = try
        map(env.searchers) do srcher
            srcher_operation(srcher)
        end
    catch e
        throw(SearchEnvConsistencyException("$e"))
    end
    return db_operation(env.dbdata), popped
end


"""
    deleteat!(env::SearchEnv, pos)

Deletes from a search environment the db and index elements with linear indices found in `pos`.
"""
Base.deleteat!(env::SearchEnv, pos) = begin
    index_operation = delete_from_index!
    !safe_indexes_method_assert(index_operation, env, AbstractVector{Int}) &&
        return nothing

    try
        map(env.searchers) do srcher
            deleteat!(srcher, pos)
        end
    catch e
        throw(SearchEnvConsistencyException("$e"))
    end
    db_deleteat!(env.dbdata, pos)
    return nothing
end
