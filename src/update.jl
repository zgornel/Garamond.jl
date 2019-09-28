"""
    updater(dbdata, fieldmaps, srchers, channels)

Updates the `srchers` using `dbdata` and communicates with
the search server using `channels`.
"""
function updater(dbdata, fieldmaps, srchers, channels)
    in_channel, out_channel = channels
    while true
        sleep(DEFAULT_SEARCHER_UPDATE_POOL_INTERVAL)
        new_srchers = similar(srchers)  # initialize
        upid = take!(in_channel)        # take id of updateable searcher
        cnt = 0
        for (i, srcher) in enumerate(srchers)
            if isempty(upid) || isequal(id(srcher), StringId(upid))
                new_srchers[i] = build_searcher(dbdata, fieldmaps, srcher.config)
                cnt+= 1
            else
                new_srchers[i] = srchers[i]
            end
        end
        @info "* Updated: $cnt searcher(s)."
        put!(out_channel, new_srchers)
    end
    return nothing
end
