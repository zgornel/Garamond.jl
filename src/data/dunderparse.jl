__parse(::Type{T}, data::AbstractString) where {T} = convert(T, data)

__parse(::Type{T}, data::AbstractString) where {T<:Number} = parse(T, data)

__parse(::Type{T}, data::AbstractString) where {T<:Symbol} = T(data)

__parse(::Type{Vector{Symbol}}, data::Vector) = Symbol.(data)

__parse(::Type{T}, data::S) where{T,S} = try
    T(data)
catch
    convert(T, data)
end
