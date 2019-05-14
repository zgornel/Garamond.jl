"""
    construct_json_request(httpreq::HTTP.Request)

Constructs a Garamond JSON search request from a HTTP request `httpreq`:
extracts the link, parses it, builds the request (in the intermediary
representation supported by the search server) and transforms it to JSON.
"""
function construct_json_request(httpreq::HTTP.Request)
    local request
    # Parse the http link to the internal request format
    # of the search server (useful to guarantee interoperability)
    try
        @debug "HTTP request $(httpreq.target) received."
        request = link2request(httpreq.target)
    catch
        request = ERRORED_REQUEST
    end
    # Convert the request to JSON
    return JSON.json(convert(Dict, request))
end


"""
    link2request(link::AbstractString)

Transforms the input HTTP `link` to a search server request format
i.e. a named tuple with specific field names.
"""
function link2request(link::AbstractString)
    # Parse link and find the offset from where the
    # actual request content starts
    parts = HTTP.URIs.splitpath(link)
    offset = findfirst(x->x=="api", parts) + 1  # jump to 'v1' position in /api/v1/...
    np = length(parts)
    if offset < np
        # Kill request
        if parts[offset+1] == "kill"
            return KILL_REQUEST

        # Read configs request
        elseif parts[offset+1] == "read-configs"
            return READCONFIGS_REQUEST

        # Update request
        elseif parts[offset+1] == "update"
            if offset+2 <= np
                return SearchServerRequest(op="update", query=parts[offset+2])
            else
                return UPDATE_REQUEST  # no searcher specified
            end

        # Search request
        elseif parts[offset+1] == "search"
            custom_weights = Dict{String, Float64}()
            if np - offset >= 7  # custom weights present
                custom_weights = parse_custom_weights(parts[offset+7])
            end
            try
                return SearchServerRequest(
                    op=parts[offset+1],
                    max_matches=parse(Int, parts[offset+2]),
                    search_method=Symbol(parts[offset+3]),
                    max_suggestions=parse(Int, parts[offset+4]),
                    what_to_return=parts[offset+5],
                    query=replace(parts[offset+6], "%20"=>" "),
                    custom_weights=custom_weights)
            catch e
                return ERRORED_REQUEST  # could not construct search request
            end
        else
            return ERRORED_REQUEST  # op is unknown
        end
    else
        return UNINITIALIZED_REQUEST  # op is missing
    end
end


# Small helper function for parsing custom weights
function parse_custom_weights(weights_str::AbstractString)
    weights = Dict{String, Float64}()
    parts = split(weights_str, "_")
    for i in 1:2:length(parts)
        try
            push!(weights, parts[i]=>parse(Float64, parts[i+1]))
        catch
            # Cannot push current pair, ignore
        end
    end
    return weights
end


"""
    rest_server(port::Integer, io_port::Integer, search_server_ready::Condition)

Starts a bi-directional REST server that uses the HTTP port `port`
and communicates with the search server through the TCP port `io_port`.
The server is started once the condition `search_server_ready`
is triggered.

# Service GET link formats:
  - search: `/api/v1/search/<max_matches>/<search_method>/<max_suggestions>
             /<what_to_return>/<query>/<custom_weights>`
  - kill server: `/api/v1/kill`
  - read configs: `/api/v1/read-configs`
where:
    <max_matches> is a number larger than 0
    <search_method> can be `exact` or `regex`
    <max_suggestions> is a number larger of equal to 0
    <what_to_return> can be `json-index` or `json-data`
    <query> can be any string (`%20` acts as space)
    <custom_weights> custom weights for the searchers

# Examples:
    `http://localhost:9001/api/v1/search/100/exact/0/json-index/something%20to%20search`
    `http://localhost:9001/api/v1/search/100/regex/3/json-index/something%20to%20search/searcher1_0.1`
    `http://localhost:9001/api/v1/read-configs`
"""
function rest_server(port::Integer, io_port::Integer, search_server_ready::Condition)
    #Checks
    if port <= 0
        @error "Please specify a HTTP REST port of positive integer value."
    end

    # Define REST endpoints to dispatch to "service" functions
    GARAMOND_REST_ROUTER = HTTP.Router()
    HTTP.@register(GARAMOND_REST_ROUTER, "GET", "/api/v1/*", construct_json_request)

    # Wait for search server to be ready
    wait(search_server_ready)
    @info "Waiting for data @http(rest):$port..."

    # Start serving requests
    @async HTTP.serve(Sockets.localhost, port, readtimeout=0) do req::HTTP.Request
        # Check for request body (there should not be any)
        body = IOBuffer(HTTP.payload(req))
        if eof(body)
            # no request body
            request = HTTP.Handlers.handle(GARAMOND_REST_ROUTER, req)
            # Send request to search server and get response
            if request isa AbstractString
                ssconn = connect(Sockets.localhost, io_port)
                println(ssconn, request)                                 # writes a "\n" as well
                response = ifelse(isopen(ssconn), readline(ssconn), "")  # expects a "\n" terminator
                close(ssconn)
                return HTTP.Response(200, ["Access-Control-Allow-Origin"=>"*"], body=response)
            end
        end
        return HTTP.Response(200, ["Access-Control-Allow-Origin"=>"*"], body="")
    end
end
