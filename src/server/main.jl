"""
    search_server(data_config_paths, socket, ws_port, http_port)

Main server function of Garamond. It is a finite-state-machine that
when called, creates the searchers i.e. search objects using the
`data_config_paths` and the proceeds to looping continuously
in order to:
    • update the searchers regularly;
    • receive requests from clients using the unix-socket
      `socket` or/and a web-socket at port `ws_port`;
    • call search and route responses back to the clients
      through their corresponding sockets

Both searcher update and I/O communication are performed asynchronously.
"""
function search_server(data_config_paths, socket, ws_port, http_port)
    # Info message
    @info "~ GARAMOND ~ $(Garamond.printable_version())\n"

    # Initialize communication Channels
    io_channel = Channel{String}(0)

    # Load data
    srchers = load_searchers(data_config_paths)

    # Start updater
    srchers_channel = Channel{typeof(srchers)}(0)
    @async updater(srchers, channels=srchers_channel)

    # Start I/O server(s)
    socket != nothing && @async unix_socket_server(socket, io_channel)
    ws_port != nothing && @async web_socket_server(ws_port, io_channel)
    http_port != nothing && @async rest_server(http_port, io_channel)

    # Main loop
    while true
        if isready(srchers_channel)
            srchers = take!(srchers_channel)
            @debug "FSM: Searchers updated."
        else
            # Read and deconstruct request
            request = take!(io_channel)
            @debug "FSM: Received request=$request"
            (operation, query, max_matches, search_method,
             max_suggestions, what_to_return) = deconstruct_request(request)
            if operation == "search"
                ### Search ###
                @info "FSM: Performing search operation query='$query'..."
                t_init = time()
                # Get search results
                results = search(srchers,
                                 query,
                                 search_method=search_method,
                                 max_matches=max_matches,
                                 max_corpus_suggestions=max_suggestions)
                t_finish = time()
                # Construct response for client
                response = construct_response(srchers,
                                              results,
                                              what_to_return,
                                              max_suggestions=max_suggestions,
                                              elapsed_time=t_finish-t_init)
                # Write response to I/O server
                put!(io_channel, response)
            elseif operation == "kill"
                ### Kill the search server ###
                @info "FSM: Exiting..."
                exit()
            elseif operation == "request_error"
                @info "FSM: Malformed request. Ignoring..."
                put!(io_channel, "")
            end
        end
    end
end
