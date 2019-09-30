"""
    updater(env, channels)

Updates the searchers from `env`. Communication with the search server
i.e. getting updatable searcher ids and sending updated searchers is done
via `channels`.
"""
function updater(env, channels)
    in_channel, out_channel = channels
    while true
        sleep(DEFAULT_SEARCHER_UPDATE_POOL_INTERVAL)
        updates = similar(env.searchers)  # initialize
        upid = take!(in_channel)        # take id of updateable searcher
        cnt = 0
        for (i, srcher) in enumerate(env.searchers)
            if isempty(upid) || isequal(id(srcher), StringId(upid))
                updates[i] = build_searcher(env.dbdata, env.fieldmaps, srcher.config)
                cnt+= 1
            else
                updates[i] = env.searchers[i]
            end
        end
        @info "* Updated: $cnt searcher(s)."
        put!(out_channel, updates)
    end
    return nothing
end
