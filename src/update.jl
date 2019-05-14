"""
    updater(srchers, in_channel, out_channel)

Function updates the `srchers` at each and puts the updates on the
`channel` to be sent to the search server.
"""
function updater(srchers::Vector{S},
                 in_channel::Channel{String},
                 out_channel::Channel{Vector{S}},
                ) where S<:Searcher
    # Loop continuously
    while true
        sleep(DEFAULT_SEARCHER_UPDATE_POOL_INTERVAL)
        new_srchers = similar(srchers)  # initialize
        upid = take!(in_channel)        # take id of updateable searcher
        cnt = 0
        for (i, srcher) in enumerate(srchers)
            if isempty(upid) || isequal(id(srcher), StringId(upid))
                new_srchers[i] = build_searcher(srcher.config)
                cnt+=1
            else
                new_srchers[i] = srchers[i]
            end
        end
        @info "* Updated: $cnt searcher(s)."
        put!(out_channel, new_srchers)
    end
    return nothing
end
