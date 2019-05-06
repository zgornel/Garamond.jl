"""
    web_socket_server(port::UInt16, channel::Channel{String})

Starts a bi-directional web socket server that uses a WEB-socket
at port `port` and communicates with the search server through a
channel `channel`. The server is started once the condition
`search_server_ready` is triggered.
"""
function web_socket_server(port::UInt16,
                           channel::Channel{String},
                           search_server_ready::Condition)
    #Checks
    if port <= 0
        @error "Please specify a WEB-socket port of positive integer value."
    end

    # Wait for search server to be ready
    wait(search_server_ready)
    @info "Waiting for data @web-socket:$port..."

    # Start serving requests
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
