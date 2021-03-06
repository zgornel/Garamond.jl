#=
REST API Specification
----------------------

    • Malformed GET, POST requests return a HTTP 400 i.e. Bad Request
    • Correct resutls return a HTTP 200 i.e. OK

    • GET:  /*                    returns a HTTP 501 message i.e. Not Implemented
    • GET:  /api/kill             kills the server
    • GET:  /api/read-configs     returns the searcher configurations

    • POST: /*                    returns a HTTP 501 message i.e. Not Implemented
    • POST: /api/envop            loads (deserializes)/ saves (serializes)/ re-indexes the search environment
    • POST: /api/search           triggers a search using parameters from the HTTP message body
    • POST: /api/recommed         triggers a recommendation using parameters from the HTTP message body
    • POST: /api/rank             triggers a ranking i.e. boost using parameters from the HTTP message body

HTTP Message body specification for the search, recommend, ranking and environment operations
---------------------------------------------------------------------------------------
    • /api/envop body format (JSON):
         {
          "cmd" : <the environment operation to be performed, a string; available: 'load', 'save' and 'reindex'>,
          "cmd_argument": <argument for the operation, a string; for 'load' and 'save' it should be a filepath,
                           for 'reindex' it should be either a searcher id or '*' i.e. all searchers>
         }
    • /api/search body format (JSON):
         {
          "query" : <the query to be performed, a string>,
          "input_parser": <the input parser to use; available: 'noop_input_parser', 'base_input_parser'>
          "return_fields" : <a list of string names for the fields to be returned>,
          "sort_fields" : <OPTIONAL, a list of string names for the fields to sort by when filtering. Sort precedence is given by list order>,
          "sort_reverse" : <OPTIONAL, whether to reverse the sorting i.e. largest number/letter first>,
          "search_method" : <OPTIONAL, a string defining the type of classic search method>,
          "searchable_filters" : <OPTIONAL, a list of fields whose values will also be part of search if used for filtering>
          "max_matches" : <OPTIONAL, an integer defining the maximum number of results for search>,
          "response_size" : <OPTIONAL, an integer defining the maximum number of results to be actually returned>,
          "response_page" : <OPTIONAL, an integer that specifies which page of 'response_size' results to return>,
          "max_suggestions" : <OPTIONAL, an integer defining the maximum number of suggestions / mismatches keyword>,
          "custom_weights" : <OPTIONAL, a dictionary where the keys are strings with searcher ids and values
                              the weights of the searchers in the result aggregation>
          "ranker": <OPTIONAL, the ranked to use; available: 'noop_ranker'>
         }

    • /api/recommend body format (JSON):
         {
          "recommender": <a string with the name of the recommender to use; available: 'noop_recommender', 'search_recommender'>
          "recommend_id" : <the id of the entity for which recommendations are sought>
          "recommend_id_key": <the db name of the column holding the id value>
          "input_parser": <the input parser to use; available: 'noop_input_parser', 'base_input_parser'>
          "filter_fields" : <a list of string name fields containing the fields that will be used by the recommender>,
          "return_fields" : <a list of string names for the fields to be returned>,
          "sort_fields" : <OPTIONAL, a list of string names for the fields to sort by when filtering. Sort precedence is given by list order>,
          "sort_reverse" : <OPTIONAL, whether to reverse the sorting i.e. largest number/letter first>,
          "search_method" : <OPTIONAL, a string defining the type of classic search method>,
          "searchable_filters" : <OPTIONAL, a list of fields whose values will form a search query if used in filter_fields>,
          "max_matches" : <OPTIONAL, an integer defining the maximum number of results for recommendations>,
          "response_size" : <OPTIONAL, an integer defining the maximum number of results to be actually returned>,
          "response_page" : <OPTIONAL, an integer that specifies which page of 'response_size' results to return>,
          "max_suggestions" : <OPTIONAL, an integer defining the maximum number of suggestions / mismatches keyword>,
          "custom_weights" : <OPTIONAL, a dictionary where the keys are strings with searcher ids and values
                              the weights of the searchers in the result aggregation>
          "ranker": <OPTIONAL, the ranked to use; available: 'noop_ranker'>
         }

    • /api/rank body format (JSON):
         {
            "ranker": <a string with the name of the ranker to use; available: 'noop_ranker'>
            "rank_ids": <list of ids to rank>,
            "rank_id_key": <the db name of the column holding the id values>,
            "return_fields" : <a list of string names for the fields to be returned>,
            "response_size" : <OPTIONAL, an integer defining the maximum number of results to be actually returned>,
            "response_page" : <OPTIONAL, an integer that specifies which page of 'response_size' results to return>
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
    _HEADERS = ["Access-Control-Allow-Origin"=>"*"]
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
    HTTP.@register(GARAMOND_REST_ROUTER, "POST", "/*", __debug_wrapper(noop_req_handler))
    HTTP.@register(GARAMOND_REST_ROUTER, "POST", "/api/envop", __debug_wrapper(envop_req_handler))
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
            return HTTP.Response(501)
        elseif srchsrv_req === ERRORED_REQUEST
            # Something went wrong during handling
            return HTTP.Response(400)
        elseif srchsrv_req isa InternalRequest
            # All OK, send request to search server and get response
            ssconn = TCPSocket()
            try
                Sockets.connect!(ssconn, Sockets.localhost, io_port)
            catch
                return HTTP.Response(503)
            end
            println(ssconn, request2json(srchsrv_req))                   # writes a "\n" as well
            response = ifelse(isopen(ssconn), readline(ssconn), "")      # expects a "\n" terminator
            close(ssconn)
            return HTTP.Response(200, _HEADERS, body=response)
        else
            return HTTP.Response(400)
        end
    end
end


# Handlers (receive a HTTP request and return a search server request)
noop_req_handler(req::HTTP.Request) = UNINITIALIZED_REQUEST


kill_req_handler(req::HTTP.Request) = KILL_REQUEST


read_configs_req_handler(req::HTTP.Request) = READCONFIGS_REQUEST


envop_req_handler(req::HTTP.Request) = begin
    return InternalRequest(operation=:envop, query=httpbody2string(req))
end


search_req_handler(req::HTTP.Request) = begin
    parameters = httpbody2dict(req)
    return InternalRequest(
                operation = :search,
                query = parameters["query"],  # if missing, throws
                input_parser = Symbol(parameters["input_parser"]),  # if missing, throws
                return_fields = Symbol.(parameters["return_fields"]),  # if missing, throws
                sort_fields = Symbol.(get(parameters, "sort_fields", DEFAULT_SORT_FIELDS)),
                sort_reverse = get(parameters, "sort_reverse", DEFAULT_SORT_REVERSE),
                search_method = Symbol(get(parameters, "search_method", DEFAULT_SEARCH_METHOD)),
                searchable_filters = Symbol.(get(parameters, "searchable_filters", String[])),
                max_matches = get(parameters, "max_matches", DEFAULT_MAX_MATCHES),
                response_size = get(parameters, "response_size", DEFAULT_RESPONSE_SIZE),
                response_page = get(parameters, "response_page", DEFAULT_RESPONSE_PAGE),
                max_suggestions = get(parameters, "max_suggestions", DEFAULT_MAX_SUGGESTIONS),
                custom_weights = get(parameters, "custom_weights", DEFAULT_CUSTOM_WEIGHTS),
                ranker = Symbol(get(parameters, "ranker", DEFAULT_RANKER_NAME)))
end


recommend_req_handler(req::HTTP.Request) = begin
    parameters = httpbody2dict(req)
    _query = parameters["recommend_id"] * " " * join(parameters["filter_fields"], " ")
    return InternalRequest(
                operation = :recommend,
                recommender = Symbol(parameters["recommender"]),  # if missing, throws
                request_id_key = Symbol.(parameters["recommend_id_key"]),  # if missing, throws
                query = _query,
                input_parser = Symbol(parameters["input_parser"]),  # if missing, throws
                return_fields = Symbol.(parameters["return_fields"]),  # if missing, throws
                sort_fields = Symbol.(get(parameters, "sort_fields", DEFAULT_SORT_FIELDS)),
                sort_reverse = get(parameters, "sort_reverse", DEFAULT_SORT_REVERSE),
                search_method = Symbol(get(parameters, "search_method", DEFAULT_SEARCH_METHOD)),
                searchable_filters = Symbol.(get(parameters, "searchable_filters", String[])),
                max_matches = get(parameters, "max_matches", DEFAULT_MAX_MATCHES),
                response_size = get(parameters, "response_size", DEFAULT_RESPONSE_SIZE),
                response_page = get(parameters, "response_page", DEFAULT_RESPONSE_PAGE),
                max_suggestions = get(parameters, "max_suggestions", DEFAULT_MAX_SUGGESTIONS),
                custom_weights = get(parameters, "custom_weights", DEFAULT_CUSTOM_WEIGHTS),
                ranker = Symbol(get(parameters, "ranker", DEFAULT_RANKER_NAME)))
end


rank_req_handler(req::HTTP.Request) = begin
    parameters = httpbody2dict(req)
    _all_ids = strip.(parameters["rank_ids"])  # if missing, throws
    return InternalRequest(
                operation = :rank,
                ranker = Symbol(parameters["ranker"]),  # if missing, throws
                query = join(_all_ids, " "),
                request_id_key = Symbol.(parameters["rank_id_key"]),   # if missing, throws
                return_fields = Symbol.(parameters["return_fields"]),  # if missing, throws
                response_size = get(parameters, "response_size", length(_all_ids)),
                response_page = get(parameters, "response_page", DEFAULT_RESPONSE_PAGE))
end


httpbody2string(req::HTTP.Request) = read(IOBuffer(HTTP.payload(req)), String)
httpbody2dict(req::HTTP.Request) = JSON.parse(httpbody2string(req))
