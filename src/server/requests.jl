#=
Structure for the internal (search server) representation
of requests.
=#
mutable struct SearchServerRequest
    operation::Symbol
    query::String
    max_matches::Int
    search_method::Symbol
    max_suggestions::Int
    return_fields::Vector{Symbol}
    custom_weights::Dict{Symbol,Float64}
end

# Keyword argument constructor
SearchServerRequest(;operation=:uninitialized_request,
                     query="",
                     max_matches=DEFAULT_MAX_MATCHES,
                     search_method=DEFAULT_SEARCH_METHOD,
                     max_suggestions=DEFAULT_MAX_SUGGESTIONS,
                     return_fields=Symbol[],
                     custom_weights=DEFAULT_CUSTOM_WEIGHTS)=
    SearchServerRequest(operation, query, max_matches, search_method,
                        max_suggestions, return_fields, custom_weights)


#=
Convert from SearchServerRequest to Dict - the latter will have
String keys with names identical to the request type fields
=#
convert(::Type{Dict}, request::T) where {T<:SearchServerRequest}= begin
    returned_dict = Dict{Symbol, Any}()
    for field in fieldnames(T)
        push!(returned_dict, field => getproperty(request, field))
    end
    return returned_dict
end


"""
Default request.
"""
const UNINITIALIZED_REQUEST = SearchServerRequest(operation=:uninitialized_request)

"""
Request corresponding to an error i.e. in parsing.
"""
const ERRORED_REQUEST = SearchServerRequest(operation=:error)

"""
Request corresponding to a kill server command.
"""
const KILL_REQUEST = SearchServerRequest(operation=:kill)

"""
Request corresponding to a searcher read configuration command.
"""
const READCONFIGS_REQUEST = SearchServerRequest(operation=:read_configs)

"""
Request corresponding to a searcher update command.
"""
const UPDATE_REQUEST = SearchServerRequest(operation=:update, query="")


"""
    parse(::Type{SearchServerRequest}, request::AbstractString)

Parses an outside request received from a client
into a `SearchServerRequest` usable by the search server.
"""
function parse(::Type{T}, outside_request::AbstractString) where {T<:SearchServerRequest}
    __parse_to(::Type{Vector{Symbol}}, data::Vector) = Symbol.(data)
    __parse_to(::Type{T}, data::S) where{T,S} = T(data)
    request = T()
    try
        data = JSON.parse(outside_request, dicttype=Dict{Symbol,Any})
        datafields = keys(data)
        fields = fieldnames(T)
        ftypes = fieldtypes(T)
        missing_fields = setdiff(fields, datafields)
        !isempty(missing_fields) &&
            @warn "Possibly malformed request, missing fields: $missing_fields"
        for (ft, field) in zip(ftypes, fields)
            in(field, datafields) &&
                setproperty!(request, field, __parse_to(ft, data[field]))
        end
    catch e
        @debug "Request parse error: $e. Returning ERRORED_REQUEST..."
        request = ERRORED_REQUEST
    end
    return request
end


"""
Standard response terminator. It is used in the client-server
communication mark the end of sent and received messages.
"""
const RESPONSE_TERMINATOR="\n"


"""
    build_response(dbdata, request, results, [; kwargs...])

Builds a response for an engine client using the data, request and results.
"""
function build_response(dbdata,
                        request,
                        results;
                        id_key=DEFAULT_DB_ID_KEY,
                        elapsed_time=-1.0)
    if !isempty(results)
        n_total_results = mapreduce(x->valength(x.query_matches), +, results)
    else
        n_total_results = 0
    end

    response_results = Dict{String, Vector{Dict{Symbol, Any}}}()
    return_fields = vcat(request.return_fields, id_key)  # id_key always present
    for result in results
        dict_vector = []
        sorted_scores = sort(collect(keys(result.query_matches)), rev=true)
        for score in sorted_scores
            entry_iterator =(db_select_entry(dbdata, i, id_key=id_key)
                             for i in result.query_matches[score])
            for entry in entry_iterator
                dict_entry = Dict(filter(nt->in(nt[1], return_fields), pairs(entry)))
                push!(dict_entry, :score => score)  # hard-push score
                push!(dict_vector, dict_entry)
            end
        end
        push!(response_results, result.id.value => dict_vector)
    end

    response = Dict("elapsed_time"=>elapsed_time,
                    "results" => response_results,
                    "n_total_results" => n_total_results,
                    "n_searchers" => length(results),
                    "n_searchers_w_results" => mapreduce(r->!isempty(r.query_matches), +, results),
                    "suggestions" => squash_suggestions(results, request.max_suggestions))
    JSON.json(response)
end
