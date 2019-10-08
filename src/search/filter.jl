function indexfilter(dbdata::NDSparse,
                     filter_query;
                     id_key=DEFAULT_DB_ID_KEY,
                     exclude=nothing)::Vector{Int}

    extract_id = dbdata -> map(x -> getproperty(x, id_key), keys(dbdata))
    f_exclude(val) = x -> setdiff(x, [val])

    # Filter using the index values
    index_values = collect(get(filter_query, col, Colon()) for col in colnames(dbdata.index))
    index_values != fill(Colon(), length(index_values)) && (dbdata = dbdata[index_values...])

    # Build selectors and filter data
    selectors = Tuple(key => __filter_from_values(val) for (key, val) in filter_query
                      if key in colnames(dbdata.data))
    !isempty(selectors) && (dbdata = filter(all, dbdata, select=selectors))
    return dbdata |> extract_id |> f_exclude(exclude)
end


function indexfilter(dbdata::IndexedTable,
                     filter_query;
                     id_key=DEFAULT_DB_ID_KEY,
                     exclude=nothing)::Vector{Int}

    extract_id = x -> select(x, id_key)
    f_exclude(val) = x -> setdiff(x, [val])

    # Build selectors and filter data
    selectors = Tuple(key => __filter_from_values(val) for (key, val) in filter_query
                      if key in colnames(dbdata))
    !isempty(selectors) && (dbdata = filter(all, dbdata, select=selectors))
    return dbdata |> extract_id |> f_exclude(exclude)
end


# Function with methods for constructing data filtering functions (x is the current value for a column)
__filter_from_values(val) = x -> x == val                # filter by equality to a value

__filter_from_values(vals::Tuple) = x -> x in vals       # filter by being present in a set

__filter_from_values(vals::NTuple{N,T}) where {N, T<:AbstractString} =
    x -> any(map(v -> occursin(x, v), vals))        # filter by being a substring of any string in a set

__filter_from_values(vals::Vector) = x -> x >= vals[1] && x <= vals[2]  # filter by belonging to an interval
