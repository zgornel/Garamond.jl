function generate_query(req::AbstractString, dbdata; recommend_id_key=DEFAULT_DB_ID_KEY)
    # Initializations
    dbschema = db_create_schema(dbdata)
    target_id, fields = __parse_query_generation_request(req, dbschema,
                            recommend_id_key=recommend_id_key)
    columns = getproperty.(dbschema, :column)

    # Filter on id, find record
    target_record = db_select_entry(dbdata, target_id; id_key=recommend_id_key)

    # Extract all values using fields (if empty, use all default query generation fields)
    query_toks = Vector{String}()
    if !isempty(target_record)
        for field in fields
            if field in columns
                value = getproperty(target_record, field)
                value_for_query = __transform_value_for_search(value)
                push!(query_toks, "$field:$(value_for_query)")
            end
        end
    end
    query = join(query_toks, " ")
    return (query=query, id=target_id)
end


function __parse_query_generation_request(req::AbstractString,
                                          dbschema;
                                          recommend_id_key=DEFAULT_DB_ID_KEY)
    # Get target id and fields from request string
    toks = split(req)
    _target_id, fields = try
        (string(toks[1]), Symbol.(toks[2:end]))
    catch e
        @debug "Could not parse target id, fields: $e"
        ("", Symbol[])
    end
    _target_id_type = typeof(_target_id)

    # Get target id type
    for dse in dbschema
        dse.column === recommend_id_key && (_target_id_type = dse.coltype)
    end

    # Parse target id
    target_id = __parse(_target_id_type, _target_id)
    return target_id, fields
end


__transform_value_for_search(value) = value  # default for non-floats, strings, leave untouched

__transform_value_for_search(value::AbstractFloat) = "[$(0.9*value), $(1.1*value)]"

__transform_value_for_search(value::AbstractString) = "\"" * value * "\""  # simple string, wrap in quotes
