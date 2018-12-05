function ioserver(socketfile=""; channel=Channel{String}(0))
    # Checks
    if issocket(socketfile)
        rm(socketfile)
    elseif isempty(socketfile)
        @error "No socket file specified, cannot create Garamond socket."
    elseif isfile(socketfile)
        @error "$socketfile already exists, cannot create Garamond socket."
    elseif isdir(socketfile)
        @error "$socketfile is a directory, cannot create Garamond socket."
    else
        socketfile = abspath(socketfile)
        _path = strip.(split(socketfile, "/"))
        directory = join(_path[1:end-1], "/")
        !isdir(directory) && mkpath(directory)
    end
    server = listen(socketfile)
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
