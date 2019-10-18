function indexfilter(dbdata,
                     filter_query;
                     id_key=DEFAULT_DB_ID_KEY,
                     exclude=nothing)::Vector{Int}
    # Function with methods for constructing data filtering functions (x is the current value for a column)
    __filter_from_values(val) = x -> x == val               # filter by equality to a value

    __filter_from_values(vals::Tuple) = x -> x in vals      # filter by being present in a set

    __filter_from_values(vals::NTuple{N,T}) where {N, T<:AbstractString} =
        x -> any(v -> occursin(v, x), vals)                 # filter by having at least one value from a string set

    __filter_from_values(vals::AbstractVector) = begin
        len = length(vals)
        if len == 1
            return x -> x == vals[1]
        elseif len >= 2
            return x -> x >= vals[1] && x <= vals[2]        # filter by belonging to an interval
        else
            return x -> false
        end
    end


	# Create selectors and filter data
    selectors = Tuple(key => __filter_from_values(val)
                      for (key, val) in filter_query
                      if key in colnames(dbdata))
    !isempty(selectors) &&
        (dbdata = filter(all, dbdata, select=selectors))

    # Return ids (use row iterator as it contains all fields)
    return setdiff(rows(dbdata, id_key), [exclude])
end
