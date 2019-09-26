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

getproperty2string(nt, prop) = begin
    if hasproperty(nt, prop)
        return string.(getproperty(nt, prop))
    else
        return ""
    end
end


# concatenate fields of dbentry (which is a named tuple) into a vector of strings
function dbentry2sentence(dbentry, fields)
    # TODO(Corneliu): Make this work for String vectors as well (i.e. nested structures)
    filter!(!isempty, String[getproperty2string(dbentry, field) for field in fields])
end


function dbentry2metadata(dbentry, fieldmap; language=DEFAULT_LANGUAGE_STR)
    #TODO(Corneliu) Make generic with respect to metadata type
    metafields = fieldnames(DocumentMetadata)
    metadata = DocumentMetadata(language, ("" for _ in 1:9)...)
    for (dbfield, metafield) in fieldmap
        # The mapping is from JuliaDB field/column to DocumentMetadata field
        _data = lowercase(getproperty2string(dbentry, dbfield))
        if metafield == :language
            # Explicitly override language if a language field is present
            lang = get(STR_TO_LANG, _data, DEFAULT_LANGUAGE)()
            setfield!(metadata, metafield, lang)
        elseif metafield in metafields
            # Non-language field
            setfield!(metadata, metafield, _data)
        end
    end
    return metadata
end
