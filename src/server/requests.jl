# Structure for the internal (search server) representation
# of requests.
struct SearchServerRequest
    op::String
    query::String
    max_matches::Int
    search_method::Symbol
    max_suggestions::Int
    what_to_return::String
    custom_weights::Dict{String,Float64}
end

# Keyword argument constructor
SearchServerRequest(;op::String="uninitialized_request",
                     query::String="",
                     max_matches::Int=0,
                     search_method::Symbol=:nothing,
                     max_suggestions::Int=0,
                     what_to_return::String="",
                     custom_weights::Dict{String,Float64}=Dict{String,Float64}())=
    SearchServerRequest(op, query, max_matches, search_method,
                        max_suggestions, what_to_return, custom_weights)


# Convert from SearchServerRequest to Dict
convert(::Type{Dict}, request::SearchServerRequest) =
    Dict{String, Any}("operation" => request.op,
                      "query" => request.query,
                      "max_matches" => request.max_matches,
                      "search_method" => request.search_method,
                      "max_suggestions" => request.max_suggestions,
                      "what_to_return" => request.what_to_return,
                      "custom_weights" => request.custom_weights)


"""
Default deconstructed request (its fields need to be initialized).
"""
const UNINITIALIZED_REQUEST = SearchServerRequest(op="uninitialized_request")

"""
Standard deconstructed request corresponding to an error request.
"""
const ERRORED_REQUEST = SearchServerRequest(op="request_error")

"""
Standard deconstructed request corresponding to a kill request.
"""
const KILL_REQUEST = SearchServerRequest(op="kill")

"""
Standard deconstructed request corresponding to a kill request.
"""
const READCONFIGS_REQUEST = SearchServerRequest(op="read_configs")


"""
    deconstruct_request(request::AbstractString)

Function that deconstructs a Garamond JSON request received from a client
into a `SearchServerRequest` usable by the search server
"""
function deconstruct_request(request::AbstractString)
    try
        # Parse JSON request
        data = JSON.parse(request)
        # Read fields
        return SearchServerRequest(
            op = get(data, "operation", "uninitialized_request"),
            query = get(data, "query", ""),
            max_matches = get(data, "max_matches", 0),
            search_method = Symbol(get(data, "search_method", :nothing)),
            max_suggestions = get(data, "max_suggestions", 0),
            what_to_return = get(data, "what_to_return", ""),
            custom_weights = Dict{String, Float64}(get(data, "custom_weights", Dict()))
           )
    catch e
        @debug "Could not deconstruct request: $e. Passing ERRORED_REQUEST to search server..."
        return ERRORED_REQUEST
    end
end


"""
    construct_response(srchers, results, what [; kwargs...])

Function that constructs a JSON response for a Garamond client using
the search `results`, data from `srchers` and specifier `what`.
"""
function construct_response(results, corpora;
                            max_suggestions::Int=0,
                            elapsed_time::Float64=0) where C<:Corpus
    local result_data
    if corpora == nothing
        # Get basic response data
        result_data = get_basic_result_data(results,
                        max_suggestions, elapsed_time)
    else
        # Get extended response data
        result_data = get_extended_result_data(results, corpora,
                        max_suggestions, elapsed_time)
    end
    return JSON.json(result_data)
end


# Get basic results data
function get_basic_result_data(results::T,
                               max_suggestions::Int,
                               elapsed_time::Float64
                              ) where T<:AbstractVector{<:SearchResult}
    # TODO: Decide on a final format
    return results
end


# Get extended results data
# Note: This should only be used for internal testing
#       by using the `garc` and `garw` clients
function get_extended_result_data(results::T,
                                  corpora,
                                  max_suggestions::Int,
                                  elapsed_time::Float64
                                 ) where T<:AbstractVector{<:SearchResult}
    # Count the total number of results
    if !isempty(results)
        nt = mapreduce(x->valength(x.query_matches), +, results)
    else
        nt = 0
    end

    r = Dict("etime"=>elapsed_time,
             "matches" => Dict{String, Vector{Tuple{Float64, Dict{String,String}}}}(),
             "n_matches" => nt,
             "n_corpora" => length(results),
             "n_corpora_match" => mapreduce(r->!isempty(r.query_matches), +, results),
             "suggestions" => squash_suggestions(results, max_suggestions))

    # Populate the "matches" field
    for (i, (_result, crps)) in enumerate(zip(results, corpora))
        push!(r["matches"], _result.id.id => Vector{Dict{String,String}}())
        if !isempty(crps)
            for score in sort(collect(keys(_result.query_matches)), rev=true)
                for doc in (crps[i] for i in _result.query_matches[score])
                    dictdoc = convert(Dict, metadata(doc))
                    push!(r["matches"][_result.id.id], (score, dictdoc))
                end
            end
        end
    end
    return r
end
