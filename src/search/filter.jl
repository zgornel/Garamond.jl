function indexfilter(dbdata,
                     filter_query;
                     id_key=DEFAULT_DB_ID_KEY,
                     exclude=nothing)::Vector{Int}
    # Function with methods for constructing data filtering functions (x is the current value for a column)
    __filter_function(val) = x -> x == val              # filter by equality to a value

    __filter_function(val::Tuple) = x -> x in val       # filter by being present in a set

    __filter_function(val::NTuple{N,T}) where {N, T<:AbstractString} =
        x -> any(v -> occursin(v, x), val)              # filter by having at least one value from a string set

    __filter_function(val::AbstractVector) =
        x -> x >= val[1] && x <= val[2]                 # filter by belonging to an interval

    __safe_filter_function(key, val::AbstractVector) = try
        @assert length(val) >= 2
        __filter_function(val)
    catch
        @warn "Failed to generate filter function for $key:$val"
        x -> true  # pass-through
    end

    __safe_filter_function(key, val) = __filter_function(val)

	# Create selectors and filter data
    selectors = Tuple(key => __safe_filter_function(key, val)
                      for (key, val) in filter_query
                      if key in colnames(dbdata))
    !isempty(selectors) &&
        (dbdata = filter(all, dbdata, select=selectors))

    # Return ids (use row iterator as it contains all fields)
    return setdiff(rows(dbdata, id_key), [exclude])
end
