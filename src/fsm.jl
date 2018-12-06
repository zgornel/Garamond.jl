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
    ioserver(socket::Union{Int, AbstractString}, channel::Channel{String})

Wrapper for the UNIX- or WEB- socket servers.
"""
ioserver(socket::AbstractString, channel::Channel{String}) =
    unix_socket_server(socket, channel)

ioserver(socket::Int, channel::Channel{String}) =
    web_socket_server(socket, channel)


"""
    web_socket_server(port::Int, channel::Channel{String})

Starts a bi-directional web socket server that uses a WEB-socket
at port `port` and communicates with the search server through a
channel `channel`.
"""
function web_socket_server(port::Int, channel::Channel{String})
    #Checks
    if port <= 0
        @error "Please specify a WEB-socket port of positive integer value."
    end
    @async HTTP.WebSockets.listen("127.0.0.1", UInt16(port)) do ws
        while !eof(ws)
            request = readavailable(ws)
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
    @info "I/O: Waiting for data @unix-socket=$socket ..."
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



_check_socket(socket::Int) = begin
end


"""
    fsm(data_config_paths, socket)

Main finite state machine (FSM) function of Garamond. When called,
creates the searchers i.e. search objects using the `data_config_paths`
and the proceeds to looping continuously in order to:
    • update the searchers regularly;
    • receive requests from clients using `socket`, call search
      and write responses back to the clients through the `socket`;

Both searcher update and I/O communication are performed asynchronously.
"""
function fsm(data_config_paths, socket)  # data config path, ports, socket file etc
    # Info message
    @info "~ GARAMOND ~ $(Garamond.printable_version())\n"
    # Initialize communication Channels
    io_channel = Channel{String}(0)
    # Load data
    srchers = load_searchers(data_config_paths)
    # Start updater
    srchers_channel = Channel{typeof(srchers)}(0)
    @async updater(srchers, channels=srchers_channel)
    # Start I/O server
    @async ioserver(socket, io_channel)
    # Main loop
    while true
        if isready(srchers_channel)
            srchers = take!(srchers_channel)
            @debug "Searchers updated."
        else
            request = take!(io_channel)
            @info "Received request=$request"
            (command,
             query,
             max_matches,
             search_type,
             search_method,
             max_suggestions,
             what_to_return
            ) = deconstruct_request(request)
            if command == "search"
                ### Search ###
                t_init = time()
                # Get search results
                results = search(srchers,
                                 query,
                                 search_type=search_type,
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
            elseif command == "kill"
                ### Kill the search server ###
                @info "FSM: Received exit command. Exiting..."
                exit()
            end
        end
    end
end


"""
    deconstruct_request(request)

Function that deconstructs a Garamond request received from a client into
individual search engine commands and search parameters.
"""
function deconstruct_request(request::String)
    cmd = JSON.parse(request)
    return (cmd["command"],
            cmd["query"],
            cmd["max_matches"],
            Symbol(cmd["search_type"]),
            Symbol(cmd["search_method"]),
            cmd["max_suggestions"],
            cmd["what_to_return"])
end


"""
    construct_response(srchers, results, what [; kwargs...])

Function that constructs a response for a Garamond client using
the search `results`, data from `srchers` and specifier `what`.
"""
function construct_response(srchers,
                            results,
                            what::String;
                            max_suggestions::Int=0,
                            elapsed_time::Float64=0)
    buf = IOBuffer()
    if what == "pretty-print"
        # unix-socket client, pretty print
        print_search_results(buf, srchers, results,
                             max_suggestions=max_suggestions)
        println(buf, "-----")
        print(buf, "Elapsed search time: $elapsed_time seconds.")
        buf.data[buf.data.==0x0a] .= 0x09  # replace "\n" with "\t"
    elseif what == "json-index"
        # unix/web socket client, return indices of the documents
        write(buf, JSON.json(results))
    elseif what == "json-data"
        # web socket client, return document metadata
        # TODO(Corneliu): Implement this
        @warn "NOT IMPLEMENTED FUNCTIONALITY REQUIRED."
    end
    return join(Char.(buf.data))
end
