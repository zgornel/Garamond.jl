"""
K-D Tree index type for storing vectors. It is a wrapper
around a `KDTree` NN structure and performs a more efficient
search using a distance-based similarity between vectors.
"""
struct KDTreeIndex{A,D} <: AbstractIndex
    tree::KDTree{A,D}
end

KDTreeIndex(data, args...; kwargs...) = KDTreeIndex(KDTree(densify(data), args...; kwargs...))


# Nearest neighbor search method
function knn_search(index::KDTreeIndex{A,D},
                    point::AbstractVector,
                    k::Int,
                    keep::Vector{Int}=collect(1:length(index));
                    kwargs...
                   ) where {A<:AbstractArray, D<:Metric}
    # Uses Euclidean distance by default
    _k = min(k, length(keep))
    skip = idx->!in(idx, keep)
    idxs, scores = knn(index.tree, Vector(point), _k, true, skip)
    return idxs, scores
end


# Length method
length(index::KDTreeIndex) = length(index.tree.data)
