"""
    update(searcher)

Updates a Searcher from using its SearchConfig.
"""
#TODO(Corneliu): Make this efficient
function update(searcher::T) where T<:Searcher
    sconf = searcher.config
    @debug "Updating searcher $(sconf.id)..."
    return build_searcher(sconf)::T
end

function update(srchers::T) where T<:AbstractVector
    return update.(srchers)::T
end


"""
    updater(searchers, channel, update_interval)

Function that regularly updates the `searchers` at each
`update_interval` seconds, and puts the updates on the
`channel` to be sent to the search server.
"""
function updater(searchers::Vector{S};
                 channel=Channel{Vector{S}}(0),
                 update_interval::Float64=DEFAULT_SEARCHER_UPDATE_INTERVAL
                ) where S<:Searcher
    if update_interval==Inf
        # Task exits and the searcher update channel in the
        # Garamond FSM will never be ready ergo, no update.
        return nothing
    else
        while true
            @debug "Garamond update sleeping for $(update_interval)(s)..."
            sleep(update_interval)
            new_searchers = update(searchers)
            put!(ch, new_searchers)
        end
    end
    return nothing
end
