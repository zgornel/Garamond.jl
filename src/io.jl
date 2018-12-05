"""
    ioserver(socket, [;channel=Channel{String}(0)])

Starts a server that accepts connections on a UNIX socket,
reads a query, sends it to Garamond to perform the search,
receives the search results from the same channel and writes
them back to the socket.
"""
function ioserver(socket=""; channel=Channel{String}(0))
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
    server = listen(socket)
    while true
        conn = accept(server)
        @async while isopen(conn)
            @debug "Waiting for data from socket..."
            query = readline(conn, keep=true)
            @debug "Received query: $query"
            # Send query to FSM and get response
            put!(channel, query)
            search_results = take!(channel)
            # Return response
            @debug "Writing to socket ..."
            buf = IOBuffer()
            println(conn, json(search_results))
            @debug "Written the data."
        end
    end
    return nothing
end
