"""
    unix_socket_server(socket::AbstractString, channel::Channel{String})

Starts a bi-directional unix socket server that uses a UNIX-socket `socket`
and communicates with the search server through a channel `channel`.
The server is started once the condition `search_server_ready`
is triggered.
"""
function unix_socket_server(socket::AbstractString,
                            channel::Channel{String},
                            search_server_ready::Condition)
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
    wait(search_server_ready)
    server = listen(socket)
    @info "Waiting for data @unix-socket:$socket..."

    # Start serving requests
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
