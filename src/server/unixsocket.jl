"""
    unix_socket_server(socket::AbstractString, io_port::Integer, start::Condition)

Starts a bi-directional unix socket server that uses a UNIX-socket `socket`
and communicates with the search server through the TCP port `io_port`.
The server is started once the condition `start` is triggered.
"""
function unix_socket_server(socket::AbstractString,
                            io_port::Integer,
                            start::Condition)
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

    # Wait for search server to be ready
    wait(start)
    server = listen(socket)
    @info "Waiting for data @unix-socket:$socket..."

    # Start serving requests
    while true
        connection = accept(server)
        @async while isopen(connection)
            request = readline(connection, keep=true)
            if !isempty(request)
                # Send request to search server and get response
                ssconn = connect(Sockets.localhost, io_port)
                print(ssconn, request)
                response = ifelse(isopen(ssconn), readline(ssconn), "")  # expects a "\n" terminator
                close(ssconn)
                # Return response
                println(connection, response)
            end
        end
    end
    return nothing
end
