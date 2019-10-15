function db_create_schema(dbdata)
    cols = colnames(dbdata)
    coltypes = map(eltype, columns(dbdata))
    pkeys = db_get_primary_keys(dbdata)
    schema = [(column=col,
               coltype=getproperty(coltypes, col),
               pkey=in(col, pkeys))
              for col in cols]
end


db_get_primary_keys(dbdata::IndexedTable) = colnames(dbdata)[dbdata.pkey]

db_get_primary_keys(dbdata::AbstractNDSparse) = colnames(dbdata.index)


# Concatenate fields of dbentry (which is a named tuple) into a vector of strings
dbentry2text(dbentry, fields) = begin
    concatenated = [field2text(dbentry, field) for field in fields]
    filter!(!isempty, concatenated)
    return concatenated
end

field2text(nt, prop) = begin
    if hasproperty(nt, prop)
        return make_a_string(getproperty(nt, prop))
    else
        return ""
    end
end


make_a_string(value) = string(value)

make_a_string(value::AbstractVector) = join(string.(value), " ")


# Checks that the id_key exists in dbdata and that its elements are Int's
function db_check_id_key(dbdata, id_key=nothing)
    if id_key != nothing
        if !in(id_key, colnames(dbdata)) &&
            throw(ErrorException("$id_key must be a column in the loaded data"))
        elseif !(eltype(getproperty(columns(dbdata), id_key)) <: Int)
            throw(ErrorException("$id_key elements must be of Int type"))
        end
    end
end


# Selects an entry in dbdata based on the value of id from a column
# selected by id_key
function db_select_entry(dbdata, id; id_key=DEFAULT_DB_ID_KEY)
    __first(dbdata::AbstractNDSparse) = first(rows(dbdata))
	__first(dbdata) = first(dbdata)
    cols = colnames(dbdata)
    if id_key in cols
        entry = filter(isequal(id), dbdata, select=id_key)
    else
        entry = filter(x -> false, dbdata, select=cols[1])  # empty entry
    end
    !isempty(entry) && (return __first(entry))
    return entry
end


# Selects all id_key's i.e. linear ids that correspond to certain values from a column
function db_select_idxs_from_values(dbdata, values, values_key; id_key=DEFAULT_DB_ID_KEY)
    collect(rows(filter(all,
                        dbdata,
                        select=values_key=>x->in(x, values)),
                 id_key))
end


# Transforms a dbentry to a string using only fields; fields of length > max_length are trimmed
function dbentry2printable(dbentry, fields; max_length=50, separator=" - ")
    join(map(str->chop_to_length(str, max_length), dbentry2text(dbentry, fields)), separator)
end

dbentry2printable(::Nothing, fields; kwargs...) = ""


# Primitives to push/pop from IndexedTable/NDSparse
function db_check_entry_for_pushing(entry, id_key, expected_value)
    if id_key != nothing
        !hasproperty(entry, id_key) &&
            throw(ErrorException("$id_key must be a column in the loaded data"))
        getproperty(entry, id_key) != expected_value &&
            throw(ErrorException("$id_key==$expected_value condition not fulfilled"))
    end
end


push!(dbdata, entry; id_key=nothing) = begin
    db_check_id_key(dbdata, id_key)
    db_check_entry_for_pushing(entry, id_key, length(dbdata) + 1)
    push!(rows(dbdata), entry)
    nothing
end


pushfirst!(dbdata, entry; id_key=nothing) = begin
    db_check_id_key(dbdata, id_key)
    db_check_entry_for_pushing(entry, id_key, 1)
    cols = columns(dbdata)
    db_id_key_shift(dbdata, id_key, 1)
    for col in colnames(dbdata)
        pushfirst!(getproperty(cols, col), getproperty(entry, col))
    end
    nothing
end


pop!(dbdata; id_key=nothing) = map(pop!, columns(dbdata))


popfirst!(dbdata; id_key=nothing) = begin
    db_check_id_key(dbdata, id_key)
    cols = columns(dbdata)
    popped = map(popfirst!, cols)
    db_id_key_shift(dbdata, id_key, -1)
    return popped
end


deleteat!(dbdata, idxs; id_key=nothing) = begin
    db_check_id_key(dbdata, id_key)
    cols = columns(dbdata)
    map(x->deleteat!(x, idxs), cols)
    db_id_key_recreate(dbdata, id_key)
end


db_id_key_recreate(dbdata, id_key=nothing) = begin
    if id_key != nothing
        getproperty(columns(dbdata), id_key)[:].= 1:length(dbdata)
    end
    nothing
end


db_id_key_shift(dbdata, id_key=nothing, by=0) = begin
    if id_key != nothing
        getproperty(columns(dbdata), id_key)[:].+= by
    end
    nothing
end
