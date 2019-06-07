"""
    web_socket_server(port::UInt16, io_port::Integer, start::Condition [; ipaddr::String])

Starts a bi-directional web socket server that uses a WEB-socket
at address `ipaddr::String` (defaults to `"127.0.0.1"`) and port
`port` and communicates with the search server through the
TCP port `io_port`. The server is started once the condition
`start` is triggered.
"""
function web_socket_server(port::UInt16,
                           io_port::Integer,
                           start::Condition;
                           ipaddr::String="127.0.0.1")
    #Checks
    if port <= 0
        @error "Please specify a WEB-socket port of positive integer value."
    end

    # Wait for search server to be ready
    wait(start)
    @info "Web-Socket server online @$ipaddr:$port..."

    # Start serving requests
    @async HTTP.WebSockets.listen(ipaddr, port, verbose=false) do ws
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
