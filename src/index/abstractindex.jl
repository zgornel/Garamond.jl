# Exceptions
struct IndexOperationException <: Exception
    op::String
    type::String
end

Base.showerror(io::IO, e::IndexOperationException) =
    print(io, "Failed call `$(e.op)` on `$(e.type)` index.")


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


# pop!, popfirst!, push!, pushfirst!
function pop!(index::AbstractIndex)
    throw(IndexOperationException("pop!", string(typeof(index))))
end

function popfirst!(index::AbstractIndex)
    throw(IndexOperationException("popfirst!", string(typeof(index))))
end

function push!(index::AbstractIndex)
    throw(IndexOperationException("push!", string(typeof(index))))
end

function pushfirst!(index::AbstractIndex)
    throw(IndexOperationException("pushfirst!", string(typeof(index))))
end

function delete_from_index!(index::AbstractIndex, points)
    throw(IndexOperationException("delete_from_index!", string(typeof(index))))
end
