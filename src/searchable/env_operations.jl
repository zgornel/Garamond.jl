"""
    env_operator(env, channels)

Saves/Loads/Updates the search environment `env`.
Communication with the search server i.e. getting the command
and its arguments and sending back a new environment is done
via `channels`.
"""
function env_operator(env, channels)
    in_channel, out_channel = channels
    _env = env
    while true
        sleep(DEFAULT_ENVOP_SLEEP_INTERVAL)
        opdict = try
            JSON.parse(take!(in_channel))
        catch
            Dict{String, String}()
        end
        cmd = Symbol(get(opdict, "cmd", ""))
        cmd_argument = get(opdict, "cmd_argument", "")
        if cmd === :save
            try
                serialize(cmd_argument, _env)
                @info "• Environment successfully saved (serialized) in $cmd_argument."
            catch
                @warn "Could not save (serialize) environment in $cmd_argument."
            end
        elseif cmd === :load
            try
                _env = deserialize(cmd_argument)
                @info "• Environment successfully loaded (deserialized) from $cmd_argument."
            catch
                @warn "Could not load (deserialize) environment from $cmd_argument."
            end
        elseif cmd === :reindex
            try
                env_config = parse_configuration(env.config_path)
                _dbdata = env_config.data_loader()
                db_check_id_key(_dbdata, env_config.id_key)

                # Selectively reload
                new_searchers = similar(env.searchers)  # initialize
                cnt = 0
                for i in eachindex(env.searchers)
                    if cmd_argument == "*" || isequal(id(env.searchers[i]), StringId(cmd_argument))
                        new_searchers[i] = build_searcher(_dbdata, env_config.searcher_configs[i])
                        cnt+= 1
                    else
                        new_searchers[i] = env.searchers[i]
                    end
                end
                _env = SearchEnv(_dbdata, env_config.id_key, new_searchers, env_config.config_path)
                @info "• Updated $cnt searcher(s) in the environment."
            catch
                @warn "Could not update environment (searchers=$cmd_argument)."
            end
        else
            @warn "Unknown environment operation command $cmd"
        end
        put!(out_channel, _env)
    end
    return nothing
end
