# This function shoud parse an input query and return a Dict with the fields and
# values necessary to filter the data later on.
function parse_query(query, schema; separator=DEFAULT_QUERY_PARSING_SEPARATOR)
    # Define expression to match
    # TODO(Corneliu): Fix for cases "id:(1,2,3) other_id:(2,3,4)"
    MATCH_EXPR = Regex("\\w+\\s*$separator(\\s*\\w+|\\s*(\\[|\\().*(\\]|\\)))")
    # The search query simply is the reminder from the query after
    # removing all key:value(s) matches
    search_query = strip(replace(query, MATCH_EXPR=>""))

    # Initialize filter query for index columns with Colon() i.e. all
    columns = map(x->x.column, schema)
    filter_query = Dict{Symbol, Any}()

    # Populate with other filter conditions
    for m in eachmatch(MATCH_EXPR, query)
        keystr, valstr = strip.(split(m.match, separator))
        try
            key = Symbol(keystr)
            idxkey = findfirst(isequal(key), columns)
            if idxkey != nothing
                val = parse_values_string(valstr, schema[idxkey].coltype)
                push!(filter_query, key => val)
            end
        catch
            @warn "Parse error for key \"$(m.match)\", ignoring..."
        end
    end
    return (search=search_query, filter=filter_query)
end


parse_values_string(valstr::AbstractString, ::Type{T}) where {T}= begin
    if startswith(valstr, r"(\(|\[)") && endswith(valstr, r"(\)|\])")
        return eval(Meta.parse(valstr))  # a vector or tuple, evaluate
    else
        return __parse(valstr, T)  # leave unchanged
    end
end


__parse(valstr::AbstractString, ::Type{T}) where {T} = convert(T, valstr)

__parse(valstr::AbstractString, ::Type{T}) where {T<:Number} = parse(T, valstr)
