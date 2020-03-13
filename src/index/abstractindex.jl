# Exceptions
struct IndexOperationException <: Exception
    op::String
    itype::String
end

Base.showerror(io::IO, e::IndexOperationException) =
    print(io, "Failed call `$(e.op)` on `$(e.itype)` index.")


# Abstract types
abstract type AbstractIndex end

"""
    knn_search(index, point, k, keep)

Searches for the `k` nearest neighbors of `point` in data contained in
the `index`. The index may vary from a simple wrapper inside a matrix
to more complex structures such as k-d trees, etc. Only neighbors
present in `keep` are returned.
"""
function knn_search(index::AbstractIndex,
                    point::AbstractVector,
                    k::Integer,
                    keep::AbstractVector;
                    kwargs...)
    throw(IndexOperationException("knn_search", string(typeof(index))))
end


"""
    length(index)

Returns the number of points indexed in `index`.
"""
function length(index::AbstractIndex)
    throw(IndexOperationException("length", string(typeof(index))))
end


### Utility function for indexes
"""
    densify(array)

Transforms sparse arrays into dense ones.
"""
densify(m::AbstractMatrix) = m
densify(m::AbstractSparseMatrix{T,I}) where {T,I} = Matrix{T}(m)
densify(v::AbstractVector) = v
densify(v::AbstractSparseVector{T,I}) where {T,I} = Vector{T}(v)
