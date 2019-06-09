"""
BruteTree index type for storing text embeddings. It is a wrapper
around a `BruteTree` NN structure and performs brute search using
a distance-based similarity between vectors.
"""
struct BruteTreeIndex{A,D} <: AbstractIndex
    tree::BruteTree{A,D}  # Array, Distance and Element types
end

BruteTreeIndex(data::AbstractMatrix) = BruteTreeIndex(BruteTree(data))

BruteTreeIndex(data::SparseMatrixCSC{T,I}) where {T<:AbstractFloat, I<:Integer} =
    BruteTreeIndex(Matrix{T}(data))


# Nearest neighbor search method
function search(index::BruteTreeIndex{A,D},
                point::AbstractVector,
                k::Int,
                keep::Vector{Int}=collect(1:length(index))
               ) where {A<:AbstractArray, D<:Metric}
    # Uses Euclidean distance by default
    _k = min(k, length(keep))
    skip = idx->!in(idx, keep)
    idxs, scores = knn(index.tree, Vector(point), _k, true, skip)
    return idxs, scores
end


# Length method
length(index::BruteTreeIndex) = length(index.tree.data)
