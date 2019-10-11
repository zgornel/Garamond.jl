#=
REST API Specification
----------------------

    ⋅ Malformed GET, POST requests return a HTTP 400 i.e. Bad Request
    ⋅ Correct resutls return a HTTP 200 i.e. OK

    ⋅ GET:  /*                    returns a HTTP 501 message i.e. Not Implemented
    ⋅ GET:  /api/kill             kills the server
    ⋅ GET:  /api/read-configs     returns the searcher configurations
    ⋅ GET:  /api/update/*         updates all engine searchers
    ⋅ GET:  /api/update/<id>      updates the seacher with an id equal to <id>

    ⋅ POST: /*                    returns a HTTP 501 message i.e. Not Implemented
    ⋅ POST: /api/search           triggers a search using parameters from the HTTP message body
    ⋅ POST: /api/recommed         triggers a recommendation using parameters from the HTTP message body
    ⋅ POST: /api/rank             triggers a ranking i.e. boost using parameters from the HTTP message body

HTTP Message body specification for the search, recommend and rank operations
-------------------------------------------------------------------------------
    ⋅ search command format (JSON):
         {
          "query" : <the query to be performed, a string>,
          "return_fields" : <a list of string names for the fields to be returned>,
          "search_method" : <OPTIONAL, a string defining the type of classic search method>,
          "max_matches" : <OPTIONAL, an integer defining the maximum number of results>,
          "max_suggestions" : <OPTIONAL, an integer defining the maximum number of suggestions / mismatches keyword>,
          "custom_weights" : <OPTINAL, a dictionary where the keys are strings with searcher ids and values
                              the weights of the searchers in the result aggregation>
         }

    ⋅ recommend command format (JSON):
         {
          "recommend_id" : <the id of the entity for which recommendations are sought>
          "recommend_id_key": <the db name of the column holding the id value>
          "filter_fields" : <a list of string name fields containing the fields that will be used by the recommender>,
          "return_fields" : <a list of string names for the fields to be returned>,
          "search_method" : <OPTIONAL, a string defining the type of classic search method>,
          "max_matches" : <OPTIONAL, an integer defining the maximum number of results>,
          "max_suggestions" : <OPTIONAL, an integer defining the maximum number of suggestions / mismatches keyword>,
          "custom_weights" : <OPTINAL, a dictionary where the keys are strings with searcher ids and values
                              the weights of the searchers in the result aggregation>
         }

    ⋅ rank command format (JSON):
         {
            "rank_ids": <list of ids to rank>
            "rank_id_key": <the db name of the column holding the id values>
            "return_fields" : <a list of string names for the fields to be returned>
         }
=#
"""
    rest_server(port::Integer, io_port::Integer, search_server_ready::Condition [;ipaddr::String])

Starts a bi-directional HTTP REST server at address `ipaddr::String`
(defaults to `"0.0.0.0"` i.e. all ip's) that uses the TCP port `port`
and communicates with the search server through the TCP port `io_port`.
The server is started once the condition `search_server_ready`
is triggered.
"""
function rest_server(port::Integer,
                     io_port::Integer,
                     search_server_ready::Condition;
                     ipaddr::String="0.0.0.0")
    #Checks
    if port <= 0
        @error "Please specify a HTTP REST port of positive integer value."
    end

    # Small closure that prints debug information for handlers
    __debug_wrapper(handle) = (req::HTTP.Request)->begin
        @debug "HTTP request $(req.target) received."
        handle(req)
    end

    # Define REST endpoints to dispatch to "service" functions
    GARAMOND_REST_ROUTER = HTTP.Router()
    HTTP.@register(GARAMOND_REST_ROUTER, "GET", "/*", __debug_wrapper(noop_req_handler))
    HTTP.@register(GARAMOND_REST_ROUTER, "GET", "/api/kill", __debug_wrapper(kill_req_handler))
    HTTP.@register(GARAMOND_REST_ROUTER, "GET", "/api/read-configs", __debug_wrapper(read_configs_req_handler))
    HTTP.@register(GARAMOND_REST_ROUTER, "GET", "/api/update/*", __debug_wrapper(update_req_handler))
    HTTP.@register(GARAMOND_REST_ROUTER, "POST", "/*", __debug_wrapper(noop_req_handler))
    HTTP.@register(GARAMOND_REST_ROUTER, "POST", "/api/search", __debug_wrapper(search_req_handler))
    HTTP.@register(GARAMOND_REST_ROUTER, "POST", "/api/recommend", __debug_wrapper(recommend_req_handler))
    HTTP.@register(GARAMOND_REST_ROUTER, "POST", "/api/rank", __debug_wrapper(rank_req_handler))

    # Wait for search server to be ready
    wait(search_server_ready)
    @info "REST server online @$ipaddr:$port..."

    # Start serving requests
    @async HTTP.serve(Sockets.IPv4(ipaddr), port, readtimeout=0) do http_req::HTTP.Request
        srchsrv_req = try
            HTTP.Handlers.handle(GARAMOND_REST_ROUTER, http_req)
        catch e
            @debug "Error handling HTTP request.\n$e"
            ERRORED_REQUEST
        end

        if srchsrv_req === UNINITIALIZED_REQUEST
            # An unsupported endpoint was called
            return HTTP.Response(501, ["Access-Control-Allow-Origin"=>"*"], body="")
        elseif srchsrv_req === ERRORED_REQUEST
            # Something went wrong during handling
            return HTTP.Response(400, ["Access-Control-Allow-Origin"=>"*"], body="")
        elseif srchsrv_req isa InternalRequest
            # All OK, send request to search server and get response
            ssconn = connect(Sockets.localhost, io_port)
            println(ssconn, request2json(srchsrv_req))                   # writes a "\n" as well
            response = ifelse(isopen(ssconn), readline(ssconn), "")  # expects a "\n" terminator
            close(ssconn)
            return HTTP.Response(200, ["Access-Control-Allow-Origin"=>"*"], body=response)
        else
            return HTTP.Response(400, ["Access-Control-Allow-Origin"=>"*"], body="")
        end
    end
end


# Handlers (receive a HTTP request and return a search server request)
noop_req_handler(req::HTTP.Request) = UNINITIALIZED_REQUEST


kill_req_handler(req::HTTP.Request) = KILL_REQUEST


read_configs_req_handler(req::HTTP.Request) = READCONFIGS_REQUEST


update_req_handler(req::HTTP.Request) = begin
    parts = HTTP.URIs.splitpath(req.target)
    updateable = parts[findfirst(isequal("update"), parts) + 1]
    if updateable == "*"
        # update all i.e. /api/update/*
        return UPDATE_REQUEST
    else
        # no searcher specified, update all i.e. /api/update
        return InternalRequest(operation=:update, query=updateable)
    end
end


search_req_handler(req::HTTP.Request) = begin
    parameters = __http_req_body_to_json(req)
    return InternalRequest(
                operation=:search,
                query = parameters["query"],  # if missing, throws
                return_fields = Symbol.(parameters["return_fields"]),  # if missing, throws
                search_method = Symbol.(get(parameters, "search_method", DEFAULT_SEARCH_METHOD)),
                max_matches = get(parameters, "max_matches", DEFAULT_MAX_MATCHES),
                max_suggestions = get(parameters, "max_suggestions", DEFAULT_MAX_SUGGESTIONS),
                custom_weights = get(parameters, "custom_weights", DEFAULT_CUSTOM_WEIGHTS))
end


recommend_req_handler(req::HTTP.Request) = begin
    parameters = __http_req_body_to_json(req)
    _query = parameters["recommend_id"] * " " * join(parameters["filter_fields"], " ")
    return InternalRequest(
                operation=:recommend,
                request_id_key = Symbol.(parameters["recommend_id_key"]),  # if missing, throws
                query = _query,
                return_fields = Symbol.(parameters["return_fields"]),  # if missing, throws
                search_method = Symbol.(get(parameters, "search_method", DEFAULT_SEARCH_METHOD)),
                max_matches = get(parameters, "max_matches", DEFAULT_MAX_MATCHES),
                max_suggestions = get(parameters, "max_suggestions", DEFAULT_MAX_SUGGESTIONS),
                custom_weights = get(parameters, "custom_weights", DEFAULT_CUSTOM_WEIGHTS))
end


rank_req_handler(req::HTTP.Request) = begin
    parameters = __http_req_body_to_json(req)
    return InternalRequest(
                operation=:rank,
                query = parameters["rank_ids"],  # if missing, throws
                request_id_key = Symbol.(parameters["rank_id_key"]),  # if missing, throws
                return_fields = Symbol.(parameters["return_fields"])) # if missing, throws
end


__http_req_body_to_json(req::HTTP.Request) =
    JSON.parse(read(IOBuffer(HTTP.payload(req)), String))
