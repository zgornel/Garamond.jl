function db_schema(dbdata)
    cols = colnames(dbdata)
    coltypes = map(eltype, columns(dbdata))
    pkeys = _get_pkeys(dbdata)
    schema = [(column=col,
               coltype=getproperty(coltypes, col),
               pkey=in(col, pkeys))
              for col in cols]
end


_get_pkeys(dbdata::IndexedTable) = colnames(dbdata)[dbdata.pkey]

_get_pkeys(dbdata::NDSparse) = colnames(dbdata.index)

dbiterator(dbdata::NDSparse) = (merge(idx, data) for (idx, data) in zip(dbdata.index, dbdata.data))

dbiterator(dbdata::IndexedTable) = (entry for entry in dbdata)


# Concatenate fields of dbentry (which is a named tuple) into a vector of strings
function dbentry2text(dbentry, fields)
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
function check_id_key(dbdata, id_key)
    if !in(id_key, colnames(dbdata)) &&
        throw(ErrorException("$id_key must be a column in the loaded data"))
    elseif !(eltype(getproperty(columns(dbdata), id_key)) <: Int)
        throw(ErrorException("$id_key elements must be of Int type"))
    end
end
