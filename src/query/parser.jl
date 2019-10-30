# This function shoud parse an input query and return a Dict with the fields and
# values necessary to filter the data later on.
function parse_query(query,
                     dbschema;
                     separator=DEFAULT_QUERY_PARSING_SEPARATOR,
                     searchable_filters=Symbol[])

    # Function that removes all tokens containing punctuation from a string
    function remove_punct_tokens(input, punct_regex=r"[\"!?:,.\[\]\(\)\*\&\^\%\$]")
        toks = filter!(token->!occursin(punct_regex, token), split(input))
        return join(toks, " ")
    end

    # Function that parses a string into a type
    function text2type(::Type{T}, valstr::AbstractString) where {T}
        if startswith(valstr, r"(\(|\[|\")") && endswith(valstr, r"(\)|\]|\")")
            return eval(Meta.parse(valstr))  # a vector or tuple, evaluate
        else
            return __parse(T, valstr)  # leave unchanged
        end
    end

    text2searchstring(val::AbstractString) = " " * val  # String get just passed
    text2searchstring(val::NTuple{N,T}) where {N, T<:AbstractString} = " " * join(val, " ")  # concatenate string values
    text2searchstring(val) = ""                 # Other filter values types i.e. Vectors, Numbers are not supported

    # Define expression to match
    #MATCH_EXPR = Regex("\\w+\\s*$separator(\\s*\\w+|\\s*(\\[|\\().*(\\]|\\)))")
    #MATCH_EXPR = Regex("[_a-zA-Z0-9]+$separator[_a-zA-Z0-9\\(\\[\\]\\),\"]+")
    REGEX_ALPHANUM = "_a-zA-Z0-9"
    MATCH_EXPR = Regex("[$REGEX_ALPHANUM]+"*
                       "$separator"*
                       "([$REGEX_ALPHANUM]+|"*
                       "\\([$REGEX_ALPHANUM,\"\\s]+\\)|"*
                       "\\[[$REGEX_ALPHANUM,\"\\s]+\\]|"*
                       "\"[$REGEX_ALPHANUM,\\s]+\")")

    # The search query simply is the reminder from the query after
    # removing all key:value(s) matches and tokens that contain punctuation
    search_query = remove_punct_tokens(strip(replace(query, MATCH_EXPR => "")))

    # Initialize filter query for index columns with Colon() i.e. all
    columns = getproperty.(dbschema, :column)
    filter_query = Dict{Symbol, Any}()

    # Populate with other filter conditions and add to any
    # filter values to search_query if the filter field is
    # in searchable_filters
    for m in eachmatch(MATCH_EXPR, query)
        keystr, valstr = strip.(split(m.match, separator))
        key = Symbol(keystr)
        try
            idxkey = findfirst(isequal(key), columns)
            if idxkey != nothing
                # Add to filter
                val = text2type(dbschema[idxkey].coltype, valstr)
                push!(filter_query, key => val)

                # Add to search_query if key is a searchable_filter
                if key in searchable_filters
                    search_query *= text2searchstring(val)
                end
            end
        catch
            @debug "Parse error for key \"$(m.match)\", ignoring..."
        end

    end
    return (search=search_query, filter=filter_query)
end
