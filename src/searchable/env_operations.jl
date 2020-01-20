"""
    env_operator(env, channels)

Saves/Loads/Updates the search environment `env`.
Communication with the search server i.e. getting the command
and its arguments and sending back a new environment is done
via `channels`.
"""
function env_operator(env, channels)
    in_channel, out_channel = channels
    #TODO(Corneliu) Implement this
    ### while true
    ###     # Sleep and take updateble searchers IDs
    ###     sleep(DEFAULT_SEARCHER_UPDATE_POOL_INTERVAL)
    ###     updates = similar(env.searchers)  # initialize
    ###     upid = take!(in_channel)        # take id of updateable searcher

    ###     # Update data
    ###     # TODO(Corneliu): Make this bit incremental
    ###     env_config = parse_configuration(env.config_path)
    ###     _dbdata = env_config.data_loader()
    ###     db_check_id_key(_dbdata, env_config.id_key)
    ###     env.dbdata = _dbdata

    ###     # Selectively reload
    ###     cnt = 0
    ###     for (i, srcher) in enumerate(env.searchers)
    ###         if isempty(upid) || isequal(id(srcher), StringId(upid))
    ###             updates[i] = build_searcher(env.dbdata, srcher.config)
    ###             cnt+= 1
    ###         else
    ###             updates[i] = env.searchers[i]
    ###         end
    ###     end
    ###     @info "* Updated: $cnt searcher(s)."
    ###     put!(out_channel, updates)
    ### end
    return nothing
end
