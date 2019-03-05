"""
    ioserver(socket_or_port::Union{UInt16, AbstractString}, channel::Channel{String})

Wrapper for the UNIX- or WEB- socket servers.
"""
ioserver(socket::AbstractString, channel::Channel{String}) =
    unix_socket_server(socket, channel)

ioserver(port::UInt16, channel::Channel{String}) =
    web_socket_server(port, channel)

ioserver(port::Nothing, channel::Channel{String}) = nothing  # missing argument sink


"""
    web_socket_server(port::UInt16, channel::Channel{String})

Starts a bi-directional web socket server that uses a WEB-socket
at port `port` and communicates with the search server through a
channel `channel`.
"""
function web_socket_server(port::UInt16, channel::Channel{String})
    #Checks
    if port <= 0
        @error "Please specify a WEB-socket port of positive integer value."
    end
    @info "I/O: Waiting for data @web-socket:$port..."
    @async HTTP.WebSockets.listen("127.0.0.1", port, verbose=false) do ws
        while !eof(ws)
            # Read data
            data = readavailable(ws)
            # Convert to String
            request = join(Char.(data))
            if !isempty(request)
                # Send request to FSM and get response
                put!(channel, request)
                response = take!(channel)
                # Return response
                write(ws, response)
            end
        end
    end
end


"""
    unix_socket_server(socket::AbstractString, channel::Channel{String})

Starts a bi-directional unix socket server that uses a UNIX-socket `socket`
and communicates with the search server through a channel `channel`.
"""
function unix_socket_server(socket::AbstractString, channel::Channel{String})
    # Checks
    if issocket(socket)
        rm(socket)
    elseif isempty(socket)
        @error "No socket file specified, cannot create Garamond socket."
    elseif isfile(socket)
        @error "$socket already exists, cannot create Garamond socket."
    elseif isdir(socket)
        @error "$socket is a directory, cannot create Garamond socket."
    else
        socket = abspath(socket)
        _path = strip.(split(socket, "/"))
        directory = join(_path[1:end-1], "/")
        !isdir(directory) && mkpath(directory)
    end
    # Start Server
    server = listen(socket)
    # Start serving
    @info "I/O: Waiting for data @unix-socket:$socket..."
    while true
        connection = accept(server)
        @async while isopen(connection)
            request = readline(connection, keep=true)
            if !isempty(request)
                # Send request to FSM and get response
                put!(channel, request)
                response = take!(channel)
                # Return response
                println(connection, response)
            end
        end
    end
    return nothing
end


"""
    search_server(data_config_paths, socket, ws_port)

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
function search_server(data_config_paths, socket, ws_port)
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
    @async ioserver(socket, io_channel)
    @async ioserver(ws_port, io_channel)
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
