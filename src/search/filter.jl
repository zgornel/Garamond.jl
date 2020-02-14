function indexfilter(dbdata,
                     filter_query;
                     id_key=DEFAULT_DB_ID_KEY,
                     sort_keys=nothing,
                     sort_reverse=false,
                     exclude=nothing)::Vector{Int}
    # Checks
    cols = colnames(dbdata)
    if !in(id_key, cols)
        @warn "Could not find id_key='$id_key'. Returning empty id vector..."
        return Int[]
    end

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

    # Find sorting, filtering columns i.e. keys
    safe_filter_keys = ()
    if !isempty(filter_query)
        safe_filter_keys = Tuple(key for key in keys(filter_query) if key in cols)
    end

    safe_sort_keys = ()
    if sort_keys !== nothing
        safe_sort_keys = Tuple(key for key in sort_keys if key in cols)
    end

    # Sort
    if !isempty(safe_sort_keys)
        sort_select_keys = safe_filter_keys
        !in(id_key, sort_select_keys) && (sort_select_keys= (id_key, sort_select_keys...))
        dbdata = sort(dbdata, safe_sort_keys; select=sort_select_keys, rev=sort_reverse)
    end

    # Filter
    if !isempty(safe_filter_keys)
        selectors = Tuple(key => __safe_filter_function(key, filter_query[key])
                          for key in safe_filter_keys)
        dbdata = filter(all, dbdata; select=selectors)
    end

    # Return ids (use row iterator as it contains all fields)
    return setdiff(rows(dbdata, id_key), [exclude])
end


sort(t::NDSparse, by...; select=colnames(t), kwargs...) =
    sort(table(nds), by...; select=select, kwargs...)
