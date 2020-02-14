__parse(::Type{T}, data::AbstractString) where {T} = convert(T, data)

__parse(::Type{T}, data::AbstractString) where {T<:Number} = parse(T, data)

__parse(::Type{T}, data::AbstractString) where {T<:Symbol} = T(data)

__parse(::Type{Vector{Symbol}}, data::Vector) = Symbol.(data)

__parse(::Type{Dict{Symbol, T1}}, data::Dict{String, T2}
       ) where {T1<:AbstractFloat, T2} =
    Dict(Symbol(k)=>T1(v) for (k,v) in data)

__parse(::Type{T}, data::S) where{T,S} = try
    T(data)
catch
    convert(T, data)
end


safe_symbol_eval(input_symbol, default_symbol) = begin
    if isdefined(@__MODULE__, input_symbol)
        return eval(input_symbol)
    else
        @warn "$input_symbol is not defined, defaulting to $default_symbol."
        return eval(default_symbol)
    end
end


unzip(it; n=length(it), offset=0, ndims=1) = begin
    from = offset+1
    to = min(length(it), from+n-1)
    map(i->getindex(getindex.(it, i), from:to), 1:ndims)
end
