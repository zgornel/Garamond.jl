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
    request_id_key::Symbol
end

# Keyword argument constructor
SearchServerRequest(;operation=:uninitialized_request,
                     query="",
                     max_matches=DEFAULT_MAX_MATCHES,
                     search_method=DEFAULT_SEARCH_METHOD,
                     max_suggestions=DEFAULT_MAX_SUGGESTIONS,
                     return_fields=Symbol[],
                     custom_weights=DEFAULT_CUSTOM_WEIGHTS,
                     request_id_key=Symbol(""))=
    SearchServerRequest(operation, query, max_matches, search_method,
                        max_suggestions, return_fields, custom_weights,
                        request_id_key)


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

request2dict(request::T) where {T<:SearchServerRequest} =
    Dict(field => getproperty(request, field) for field in fieldnames(T))

request2json(request::T) where {T<:SearchServerRequest} =
    JSON.json(request2dict(request))


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
                setproperty!(request, field, __parse(ft, data[field]))
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
