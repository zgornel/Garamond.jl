function db_create_schema(dbdata)
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

db_create_iterator(dbdata::NDSparse) = (merge(idx, data) for (idx, data) in zip(dbdata.index, dbdata.data))

db_create_iterator(dbdata::IndexedTable) = (entry for entry in dbdata)


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
function db_check_id_key(dbdata, id_key)
    if !in(id_key, colnames(dbdata)) &&
        throw(ErrorException("$id_key must be a column in the loaded data"))
    elseif !(eltype(getproperty(columns(dbdata), id_key)) <: Int)
        throw(ErrorException("$id_key elements must be of Int type"))
    end
end


# Selects an entry in dbdata based on the value of id from a column
# selected by id_key
function db_select_entry(dbdata, id; id_key=DEFAULT_DB_ID_KEY)
    __first(dbdata::NDSparse) = first(rows(dbdata))
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


# Transforms a dbentry to a string using only fields; fields of length > max_length are trimmed
function dbentry2printable(dbentry, fields; max_length=50, separator=" - ")
    function __stringchop(str, len)
         str = replace(str, "\n"=>"")
         idxs = collect(eachindex(str))
         _idx = findlast(x->x<=len, idxs)
         if _idx == nothing
             _len=0
         else
             _len = idxs[findlast(x->x<=len, idxs)]
         end
         length(str) > len ? str[1:_len]*"..."  : str
    end
    join(map(str->__stringchop(str, max_length), dbentry2text(dbentry, fields)), separator)
end

dbentry2printable(::Nothing, fields; kwargs...) = ""


# Primitives to push/pop from IndexedTable/NDSparse
# TODO(Corneliu): Add support for updating linear index column
#                 using id_key kwarg
push!(dbdata, row) = begin
    push!(rows(dbdata), data)
    nothing
end

pushfirst!(dbdata, data) = begin
	cols = columns(dbdata)
    for col in colnames(dbdata)
        pushfirst!(getproperty(cols, col), getproperty(data, col))
    end
    nothing
end

pop!(dbdata) = map(pop!, columns(dbdata))

popfirst!(dbdata) = map(popfirst!, columns(dbdata))

deleteat!(dbdata, idxs) = begin
    map(x->deleteat!(x, idxs), columns(dbdata))
    nothing
end
