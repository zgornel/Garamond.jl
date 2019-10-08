# This function shoud parse an input query and return a Dict with the fields and
# values necessary to filter the data later on.
function parse_query(query, dbschema; separator=DEFAULT_QUERY_PARSING_SEPARATOR)
    # Function that removes all tokens containing punctuation from a string
    remove_punct_tokens(input, punct_regex=r"[\"!?:,.\[\]\(\)\*\&\^\%\$]") = begin
        toks = filter!(token->!occursin(punct_regex, token), split(input))
        return join(toks, " ")
    end

    # Function that parses a string into a type
    parse_value(::Type{T}, valstr::AbstractString) where {T}= begin
        if startswith(valstr, r"(\(|\[)") && endswith(valstr, r"(\)|\])")
            return eval(Meta.parse(valstr))  # a vector or tuple, evaluate
        else
            return __parse(T, valstr)  # leave unchanged
        end
    end

    # Define expression to match
    #MATCH_EXPR = Regex("\\w+\\s*$separator(\\s*\\w+|\\s*(\\[|\\().*(\\]|\\)))")
    MATCH_EXPR = Regex("[_a-zA-Z0-9]+$separator[_a-zA-Z0-9\\(\\[\\]\\),\"]+")

    # The search query simply is the reminder from the query after
    # removing all key:value(s) matches and tokens that contain punctuation
    search_query = remove_punct_tokens(strip(replace(query, MATCH_EXPR => "")))

    # Initialize filter query for index columns with Colon() i.e. all
    columns = getproperty.(dbschema, :column)
    filter_query = Dict{Symbol, Any}()

    # Populate with other filter conditions
    for m in eachmatch(MATCH_EXPR, query)
        keystr, valstr = strip.(split(m.match, separator))
        try
            key = Symbol(keystr)
            idxkey = findfirst(isequal(key), columns)
            if idxkey != nothing
                val = parse_value(dbschema[idxkey].coltype, valstr)
                push!(filter_query, key => val)
            end
        catch
            @debug "Parse error for key \"$(m.match)\", ignoring..."
        end
    end
    return (search=search_query, filter=filter_query)
end
