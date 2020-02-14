"""
Request object for the internal server of the engine.
"""
mutable struct InternalRequest
    operation::Symbol
    query::String
    max_matches::Int
    search_method::Symbol
    searchable_filters::Vector{Symbol}
    max_suggestions::Int
    return_fields::Vector{Symbol}
    custom_weights::Dict{Symbol,Float64}
    request_id_key::Symbol
    sort_fields::Vector{Symbol}
    sort_reverse::Bool
    response_size::Int
    response_page::Int
    input_parser::Symbol
    ranker::Symbol
    recommender::Symbol
end

# Keyword argument constructor
InternalRequest(;operation=:uninitialized_request,
                query="",
                max_matches=DEFAULT_MAX_MATCHES,
                search_method=DEFAULT_SEARCH_METHOD,
                searchable_filters=Symbol[],
                max_suggestions=DEFAULT_MAX_SUGGESTIONS,
                return_fields=Symbol[],
                custom_weights=DEFAULT_CUSTOM_WEIGHTS,
                request_id_key=Symbol(""),
                sort_fields=DEFAULT_SORT_FIELDS,
                sort_reverse=DEFAULT_SORT_REVERSE,
                response_size=DEFAULT_RESPONSE_SIZE,
                response_page=DEFAULT_RESPONSE_PAGE,
                input_parser=DEFAULT_INPUT_PARSER_NAME,
                ranker=DEFAULT_RANKER_NAME,
                recommender=DEFAULT_RECOMMENDER_NAME)=
    InternalRequest(operation,
                    query,
                    max_matches,
                    search_method,
                    searchable_filters,
                    max_suggestions,
                    return_fields,
                    custom_weights,
                    request_id_key,
                    sort_fields,
                    sort_reverse,
                    response_size,
                    response_page,
                    input_parser,
                    ranker,
                    recommender)


#=
Converts an InternalRequest to Dict - the latter will have
String keys with names identical to the request type fields
=#
convert(::Type{Dict}, request::T) where {T<:InternalRequest}= begin
    returned_dict = Dict{Symbol, Any}()
    for field in fieldnames(T)
        push!(returned_dict, field => getproperty(request, field))
    end
    return returned_dict
end

request2dict(request::T) where {T<:InternalRequest} =
    Dict(field => getproperty(request, field) for field in fieldnames(T))

request2json(request::T) where {T<:InternalRequest} =
    JSON.json(request2dict(request))


"""
Default request.
"""
const UNINITIALIZED_REQUEST = InternalRequest(operation=:uninitialized_request)

"""
Request corresponding to an error i.e. in parsing.
"""
const ERRORED_REQUEST = InternalRequest(operation=:error)

"""
Request corresponding to a kill server command.
"""
const KILL_REQUEST = InternalRequest(operation=:kill)

"""
Request corresponding to a searcher read configuration command.
"""
const READCONFIGS_REQUEST = InternalRequest(operation=:read_configs)

"""
Request corresponding to an environment operation command.
"""
const ENVOP_REQUEST = InternalRequest(operation=:envop, query="{}")


"""
    parse(::Type{InternalRequest}, request::AbstractString)

Parses an outside request received from a client
into an `InternalRequest` usable by the search server.
"""
function parse(::Type{T}, outside_request::AbstractString) where {T<:InternalRequest}
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
