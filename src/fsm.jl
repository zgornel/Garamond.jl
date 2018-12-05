"""
    updater(searchers, channel, update_interval)

Function that regularly updates the `searchers` at each `update_interval`
seconds, and puts the updates in the `channel` to be sent to the Garamond FSM.
"""
function updater(searchers::Vector{S};
                 channel=Channel{Vector{S}}(0),
                 update_interval::Float64=DEFAULT_SEARCHER_UPDATE_INTERVAL
                ) where S<:AbstractSearcher
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



"""
    fsm(data_config_paths, socket, args... [;kwargs...])

Main finite state machine (FSM) function of Garamond. When called,
creates the searchers i.e. search objects using the `data_config_paths`
and the proceeds to looping continuously in order to:
    • update the searchers regularly
    • receive queries from the `socket`, call search
      and writes the results back to the `socket`

Both searcher update and I/O communication are performed asynchronously.
"""
function fsm(data_config_paths,
             socket="/tmp/garamond/sockets/socket1",
             args...;kwargs...)  # data config path, ports, socket file etc
    # Initialize communication Channels
    io_channel = Channel(0)
    # Load data
    srchers = load_searchers(data_config_paths)
    # Start updater
    srchers_channel = Channel{typeof(srchers)}(0)
    @async updater(srchers, channels=srchers_channel)
    # Start I/O listner
    @async ioserver(socket, channel=io_channel)
    # Main loop
    while true
        if isready(srchers_channel)
            @debug "Garamond is updating searchers ..."
            srchers = take!(srchers_channel)
            @debug "Searchers updated."
        else
            @debug "Waiting for query..."
            QUERY = take!(io_channel)
            @debug "\tReceived QUERY=$QUERY"
            command, command_content, command_args = deconstruct_command(QUERY)
            ### Search ###
            t_init = time()
            sr = search(srchers, QUERY)
            t_finish = time()
            ##############
            result = construct_response(sr, t_finish-t_init)
            put!(io_channel, result)
            @debug "Search response sent."
       end
    end
end
