"""
    construct_request(req::HTTP.Request)

Constructs a Garamond JSON search request from a HTTP request `req`:
extracts the link, parses it, builds a dictionary and transforms it
to JSON.
"""
function construct_request(req::HTTP.Request)
    local offset, parts  # parts of the link
    try
        # This fails if the link is malformed
        offset = 2
        @debug "Request at $(req.target) received!"
        parts = HTTP.URIs.splitpath(req.target)
        @assert length(parts) == 8
    catch
        offset = 0
        parts = ERRORED_REQUEST
    end
    op, max_matches,
    search_method, max_suggestions,
    what_to_return, query = parts[offset+1:end]
    return JSON.json(
            Dict("operation" => op,
                 "query" => replace(query, "%20"=>" "),
                 "max_matches" => parse(Int, max_matches),
                 "search_method" => Symbol(search_method),
                 "max_suggestions" => parse(Int, max_suggestions),
                 "what_to_return" => what_to_return
                )
           )
end


"""
    rest_server(port::Integer, channel::Channel{String})

Starts a bi-directional REST server that uses the HTTP port `port`
and communicates with the search server through a channel `channel`.

Service GET link format:
    `/api/v1/<op>/<max_matches>/<search_method>/<max_suggestions>/<what_to_return>/<query>`
where:
    <op> is fixed to `search`
    <max_matches> is a number larger than 0
    <search_method> is fixed to `exact`
    <max_suggestions> is fixed to `0`
    <what_to_return> is fixed to `json-index`
    <query> can be any string

Example:
    `http://localhost:port/api/v1/search/100/exact/0/json-index/something%20to%20search`
"""
function rest_server(port::Integer, channel::Channel{String})
    #Checks
    if port <= 0
        @error "Please specify a HTTP REST port of positive integer value."
    end

    # define REST endpoints to dispatch to "service" functions
    GARAMOND_REST_ROUTER = HTTP.Router()
    HTTP.@register(GARAMOND_REST_ROUTER, "GET", "/api/v1/*", construct_request)

    @info "I/O: Waiting for data @http(rest):$port..."
    @async HTTP.serve(Sockets.localhost, port, readtimeout=0) do req::HTTP.Request
        # Check for request body (there should not be any)
        body = IOBuffer(HTTP.payload(req))
        if eof(body)
            # no request body
            request = HTTP.Handlers.handle(GARAMOND_REST_ROUTER, req)
            # Send request to FSM and get response
            if request isa AbstractString
                put!(channel, request)
                response = take!(channel)
                return HTTP.Response(200, ["Access-Control-Allow-Origin"=>"*"], body=response)
            end
        end
        return HTTP.Response(200, ["Access-Control-Allow-Origin"=>"*"], body="")
    end
end
