"""
    web_socket_server(port::UInt16, io_port::Integer, start::Condition)

Starts a bi-directional web socket server that uses a WEB-socket
at port `port` and communicates with the search server through the
TCP port `io_port`. The server is started once the condition
`start` is triggered.
"""
function web_socket_server(port::UInt16, io_port::Integer, start::Condition)
    #Checks
    if port <= 0
        @error "Please specify a WEB-socket port of positive integer value."
    end

    # Wait for search server to be ready
    wait(start)
    @info "Waiting for data @web-socket:$port..."

    # Start serving requests
    @async HTTP.WebSockets.listen("127.0.0.1", port, verbose=false) do ws
        while !eof(ws)
            # Read data
            data = readavailable(ws)
            # Convert to String
            request = join(Char.(data))
            if !isempty(request)
                # Send request to search server and get response
                ssconn = connect(Sockets.localhost, io_port)
                println(ssconn, request)                                 # writes a "\n" as well
                response = ifelse(isopen(ssconn), readline(ssconn), "")  # expects a "\n" terminator
                close(ssconn)
                # Return response
                write(ws, response)
            end
        end
    end
end
