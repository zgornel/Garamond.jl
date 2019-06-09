# Abstract types
abstract type AbstractIndex end


"""
    search(index, point, k, keep)

Searches for the `k` nearest neighbors of `point` in data contained in
the `index`. The index may vary from a simple wrapper inside a matrix
to more complex structures such as k-d trees, etc. Only neighbors
present in `keep` are returned.
"""
function search(index::AbstractIndex,
                point::AbstractVector,
                k::Integer,
                keep::AbstractVector)
    throw(ErrorException("`search` is not implemented for $(typeof(index)) indexes."))
end


"""
    length(index)

Returns the number of points indexed in `index`.
"""
function length(index::AbstractIndex)
    throw(ErrorException("`length` is not implemented for $(typeof(index)) indexes."))
end
