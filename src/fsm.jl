# Re-build searcher
function updater(searchers::Vector{S};
                 channel=Channel{Vector{S}}(0),
                 update_interval::Int=60) where S<:AbstractSearcher
    while true
        @debug "Garamond update sleeping for $(update_interval)(s)..."
        sleep(update_interval)
        new_searchers = update(searchers)
        put!(ch, new_searchers)
    end
    return nothing
end



# Main FSM function of Garamond: A FSM that loops and:
#  - updates regularly (asynchronosly)
#  - takes searchers (asynchronously)
#  - searches and writes the results (asynchronously)
function fsm(data_config_paths,
             socket="/tmp/garamond/sockets/socket1",
             args...;kwargs...)  # data config path, ports, socket file etc
    # Initialize communication Channels
    io_channel = Channel(0)
    # Load data
    srchers = load_searchers(data_config_paths)
    # Start updater
    srchers_channel = Channel{typeof(srchers)}(0)
    ### @async updater(srchers,
    ###                channels=srchers_channel,
    ###                update_interval=update_interval)
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
            result = search(srchers, QUERY)
            put!(io_channel, result)
            @debug "Search response sent."
       end
    end
end
