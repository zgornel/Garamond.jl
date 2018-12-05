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
             socket = "/tmp/garamond/sockets/socket1",
             port = -1,
             args...;kwargs...)  # data config path, ports, socket file etc
    # Initialize communication Channels
    io_channel = Channel{String}(0)
    # Load data
    srchers = load_searchers(data_config_paths)
    # Start updater
    srchers_channel = Channel{typeof(srchers)}(0)
    @async updater(srchers, channels=srchers_channel)
    # Start I/O listner
    # TODO(Corneliu) Support WebSockets through port
    @async ioserver(socket, channel=io_channel)
    # Main loop
    while true
        if isready(srchers_channel)
            @debug "Garamond is updating searchers ..."
            srchers = take!(srchers_channel)
            @debug "Searchers updated."
        else
            @debug "Waiting for query..."
            request = take!(io_channel)
            @debug "\tReceived REQUEST=$request"
            (command,
                query,
                max_matches,
                search_type,
                search_method,
                max_suggestions,
                pretty) = deconstruct_request(request)
            if command == "search"
                ### Search ###
                t_init = time()
                results = search(srchers,
                                 query,
                                 search_type=search_type,
                                 search_method=search_method,
                                 max_matches=max_matches,
                                 max_corpus_suggestions=max_suggestions)
                t_finish = time()
                response = construct_response(srchers,
                                              results,
                                              pretty=pretty,
                                              t=t_finish-t_init)
                put!(io_channel, response.data)
                @debug "Search response sent."
            elseif command == "quit" || command == "exit"
                ### quit ###
                exit()
            end
       end
    end
end


"""
    deconstruct_request(request)

Function that deconstructs a Garamond request received from a client.
"""
function deconstruct_request(request)
    cmd = JSON.parse(request)
    return (cmd["command"],
            cmd["query"],
            cmd["max_matches"],
            Symbol(cmd["search_type"]),
            Symbol(cmd["search_method"]),
            cmd["max_suggestions"],
            cmd["pretty"])
end


"""
    construct_response(results [; pretty=false, t=0])

Function that constructs a response for a Garamond client using
the search `results`. The keyword arguments `pretty` and `t` indicate
whether the response is to be formatted for easy viewing (as opposed
to machine-readable) and the time elapsed for the search respectively.
"""
# TODO(Corneliu): Improve function
function construct_response(srchers, results; pretty::Bool=false, t::Float64=0)
    response = IOBuffer()
    if pretty
        write(response, print_search_results(srchers, results))
    else
        write(response, JSON.json(results))
    end
    return response
end
