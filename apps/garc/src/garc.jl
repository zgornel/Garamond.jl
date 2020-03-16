#!/bin/julia

#############################################
# Garamond script for CLI client operations #
#############################################

module garc  # The Garamond client

using Sockets
using ArgParse
using Logging
using JSON


# Support for parsing to Symbol for the ArgParse package
import ArgParse: parse_item
function ArgParse.parse_item(::Type{Symbol}, x::AbstractString)
    return Symbol(x)
end


# Function that parses Garamond's unix-socket client arguments
function get_unix_socket_client_arguments(args::Vector{String})
	s = ArgParseSettings()
	@add_arg_table! s begin
        "query"
            help = "the search query"
            arg_type = String
            default = ""
        "--log-level"
            help = "logging level"
            default = "warn"
        "--unix-socket", "-u"
            help = "UNIX socket for data communication"
            default = ""
            arg_type = String
        "--return-fields"
            help = "List of fields to return (ignores wrong names)"
            nargs = '*'
        "--sort-fields"
            help = "List of fields to sort by when filtering (ignores wrong names)"
            nargs = '*'
        "--sort-reverse"
            help = "Reverse the filter sort order"
            arg_type = Bool
            default = false
        "--pretty"
            help = "output is a pretty print of the results"
            action = :store_true
        "--max-matches"
            help = "maximum number of results for internal neighbor searches"
            arg_type = Int
            default = 10
        "--response-size"
            help = "maximum number of results to return"
            arg_type = Int
            default = 10
        "--response-page"
            help = "index of page with results to return"
            arg_type = Int
            default = 1
        "--search-method"
            help = "type of match done during search"
            arg_type = Symbol
            default = :exact
        "--max-suggestions"
            help = "How many suggestions to return for each mismatched query term"
            arg_type = Int
            default = 0
        "--id-key"
            help = "The linear ID key"
            arg_type = String
            default = "garamond_linear_id"
        "--kill", "-k"
            help = "Kill the search engine server"
            action = :store_true
        "--env-operation"
            help = "Environment operation"
            arg_type = String
            nargs = 2
        "--ranker"
            help = "The ranker to use; avalilable: noop_ranker"
            arg_type = String
            default = "noop_ranker"
        "--input-parser"
            help = "The input parser to use; available: noop_input_parser, base_input_parser"
            arg_type = String
            default = "noop_input_parser"
	end
	return parse_args(args,s)
end


# Function that constructs a search server JSON request
# (can be a search request or a command) from a set of arguments
# that come usually from parsed client input arguments
function construct_json_request(args)
    # Construct the basic dictionary corresponding to the JSON request
    dictreq = Dict("operation" => "",
                   "query" => "",
                   "max_matches" => args["max-matches"],
                   "max_suggestions" => args["max-suggestions"],
                   "search_method" => args["search-method"],
                   "return_fields" => args["return-fields"],
                   "sort_fields" => args["sort-fields"],
                   "sort_reverse" => args["sort-reverse"],
                   "custom_weights" =>Dict(),
                   "request_id_key" => args["id-key"],
                   "response_size" => args["response-size"],
                   "response_page" => args["response-page"],
                   "ranker" => args["ranker"],
                   "input_parser" => args["input-parser"],
                   "recommender" => "noop_recommender",
                   "searchable_filters" => [])
    # Kill request
    if args["kill"]
        dictreq["operation"] = "kill"

    # Environment operation
    elseif !isempty(args["env-operation"])
        dictreq["operation"] = "envop"
        dictreq["query"] = "{\"cmd\":\"$(args["env-operation"][1])\","*
                            "\"cmd_argument\":\"$(args["env-operation"][2])\"}"
    else
        dictreq["operation"] = "search"
        dictreq["query"] = args["query"]
    end
    return JSON.json(dictreq)
end


# Deconstruct response is a pass through right now
deconstruct_json_response(response) = response


# Function that performs a simple search i.e. sends data to
# a socket, reads from the socket and outputs to STDOUT
function iosearch(connection, request, pretty=false)
    # Checks
    if isopen(connection)
        println(connection, request)
        @debug ">>> Request sent."
        response = readline(connection, keep=true)
        @debug "<<< Search results received."
    else
        @error "Connection is closed."
    end
    # Deconstruct response
    data = deconstruct_json_response(response)
    if pretty
        try
            jr = JSON.parse(data)  # builds a Dict
            # Print search results in a way similar to that
            # of the web client (`garw` web page)
            println("Elapsed search time: $(jr["elapsed_time"])s.")
            println(jr["n_searchers_w_results"], "/", jr["n_searchers"],
                    " search ensemble yielded ", jr["n_total_results"], " results.")
            for (id, result) in jr["results"]
                !isempty(result) && println("$id")
                for entry in result
                    printable = "["*string(entry["score"])*"] ~ "
                    for (k, v) in entry
                        k!="score" && (printable*= (k * ": " *string(v) * " "))
                    end
                    println(stdout, printable)
                end
            end
            # Print suggestions
            suggestions = jr["suggestions"]["d"]
            ns = length(suggestions)
            ns > 0 && println("$ns suggestions:")
            for (keyword, suggest) in suggestions
                print("  \"$keyword\": ")
                println("$(join(map(x->x[2], suggest), ", "))")
            end
        catch
            @warn "Pretty printing failed, dumping data as is..."
            println(stdout, data)
        end
    else
        println(stdout, data)
    end
    return nothing
end


########################
# Main module function #
########################
function julia_main()::Cint
    try
        real_main()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end


function real_main()
    # Parse command line arguments
    args = get_unix_socket_client_arguments(ARGS)

    # Logging
    log_levels = Dict("debug" => Logging.Debug,
                      "info" => Logging.Info,
                      "warning" => Logging.Warn,
                      "error" => Logging.Error)
    logger = ConsoleLogger(stdout,
                get(log_levels, lowercase(args["log-level"]), Logging.Info))
    global_logger(logger)

    # Start client
    @debug "~ GARAMOND~ (unix-socket client)"
    unixsocket = args["unix-socket"]
    if issocket(unixsocket)
        conn = connect(unixsocket)
        if isempty(args["query"]) && !args["kill"]
            @warn "Empty query, nothing to search. Exiting..."
        else
            # Construct Garamond request
            request = construct_json_request(args)
            # Search
            iosearch(conn, request, args["pretty"])
        end
        # Close connection and exit
        close(conn)
    else
        @warn "$unixsocket is not a proper UNIX socket. Exiting..."
    end
    return 0
end


##############
# Run client #
##############
if abspath(PROGRAM_FILE) == @__FILE__
    real_main()
end

end  # module
