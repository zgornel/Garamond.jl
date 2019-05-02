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
    @info "Waiting for data @web-socket:$port..."
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
