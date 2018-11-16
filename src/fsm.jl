# Re-build searcher
function updater(srcher::S; channel::C=Channel(0), update_interval::Int=5
                ) where {C<:AbstractChannel, S<:AbstractSearcher}
    while true
        println("[updater] sleeping $(t)s...")
        sleep(t)
        new_srcher = update(srcher)
        put!(ch, data)
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
    srcher_channel = Channel(0)
    io_channel = Channel(0)

    # Logging
    logger = ConsoleLogger(stdout, Logging.Debug)
    global_logger(logger)

    # Load data
    srchers = load_searchers(data_config_paths)

    # Start updater
    #@async updater(data, 1, channel=srcher_channel)

    # Start I/O listner
    socket =
    @async ioserver(socket, channel=io_channel)

    # Main loop
    n = 3 # Maximum 3 searches and its over :)
    while n > 0
        if isready(srcher_channel)
            @info "[main] updating!"
            data = take!(srcher_channel)
            n-=1
       else
           @info "[main] Waiting for query..."
           QUERY = take!(io_channel)
           @info "[main] QUERY: $QUERY"
           result = search(srchers, QUERY)
           @info "[main] Writing result for query..."
           put!(io_channel, result)
       end
    end
end
