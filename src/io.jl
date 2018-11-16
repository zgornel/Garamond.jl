function ioserver(socketfile=""; channel=Channel(0))
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
        directory = join(_path[1:end-1])
        !isdir(directory) && mkpath(directory)
    end
    server = listen(socketfile)
    while true
        conn = accept(server)
        @async while isopen(conn)
            @debug "\t[io module] Waiting for data from socket..."
            query = readline(conn, keep=true)
            @debug "\t[io module] received: $query"
            # Send query to FSM and get response
            put!(channel, query)
            search_results = take!(channel)
            # Return response
            @debug "\t[io module] Writing to socket ..."
            buf = IOBuffer()
            write(conn, json(search_results)*"\n")
            @debug "\t[io module] Written the data."
        end
    end
    return nothing
end


function iosearch(connection, query)  # search option would go here
    # Checks
    if isopen(connection)
        println(connection, query)
        response = readline(connection, keep=true)
    else
        @error "Connection is is closed."
    end
    # Return Dict
    println(stdout, response)
end
