##################################################
# Search index structures and associated methods #
##################################################
"""
Naive index type for storing text embeddings. It is a wrapper
around a matrix of embeddings and performs brute search using
the cosine similarity between vectors.
"""
struct NaiveIndex{E, A<:AbstractMatrix{E}} <: AbstractIndex
    data::A
end


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


"""
K-D Tree index type for storing text embeddings. It is a wrapper
around a `KDTree` NN structure and performs a more efficient
search using a distance-based similarity between vectors.
"""
struct KDTreeIndex{A,D} <: AbstractIndex
    tree::KDTree{A,D}
end

KDTreeIndex(data::AbstractMatrix) = KDTreeIndex(KDTree(data))

KDTreeIndex(data::SparseMatrixCSC{T,I}) where {T<:AbstractFloat, I<:Integer} =
    KDTreeIndex(Matrix{T}(data))


"""
HNSW index type for storing text embeddings. It is a wrapper around a
`HierarchicalNSW` (Hierarchical Navigable Small Worlds) NN graph
structure and performs a very efficient search using a distance-based
similarity between vectors.

# References
 * [Y. A. Malkov, D.A. Yashunin "Efficient and robust approximate nearest
neighbor search using Hierarchical Navigable Small World graphs"]
(https://arxiv.org/abs/1603.09320)
"""
struct HNSWIndex{I,E,A,D} <: AbstractIndex
    tree::HierarchicalNSW{I,E,A,D}
end

HNSWIndex(data::AbstractMatrix{T}) where T<:AbstractFloat = begin
    _data = _build_hnsw_data(data)
    hnsw = HierarchicalNSW(_data;
                           efConstruction=100,
                           M=16,
                           ef=50)
    add_to_graph!(hnsw)
    return HNSWIndex(hnsw)
end

_build_hnsw_data(data::AbstractMatrix) = [Vector(data[:,i]) for i in 1:size(data,2)]
_build_hnsw_data(data::Matrix) = [data[:,i] for i in 1:size(data,2)]


# Nearest neighbor search methods
"""
    search(index, point, k)

Searches for the `k` nearest neighbors of `point` in data contained in
the `index`. The index may vary from a simple wrapper inside a matrix
to more complex structures such as k-d trees, etc.
"""
function search(index::NaiveIndex{E,A},
                point::AbstractVector,
                k::Int,
                keep::Vector{Int}=collect(1:length(index))
               ) where {E<:AbstractFloat, A<:AbstractMatrix{E}}
    _k = min(k, length(keep))
    # Cosine similarity
    scores = index.data[:, keep]' * point
    idxs = sortperm(scores, rev=true)[1:_k]
    return keep[idxs], one(E) .- scores[idxs]
end

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

function search(index::KDTreeIndex{A,D},
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

function search(index::HNSWIndex{I,E,A,D},
                point::AbstractVector,
                k::Int,
                keep::Vector{Int}=collect(1:length(index))
               ) where {I<:Unsigned, E<:Real, A<:AbstractArray, D<:Metric}
    # Uses Euclidean distance by default
    _idxs, scores = knn_search(index.tree, Vector(point), k)
    idxs = Int.(_idxs)
    if length(keep) == length(index)
        # all data points are valid
        return idxs, scores
    else
        # this bit is slow if 'keep' is large
        mask = map(idx->in(idx, keep), idxs)
        return idxs[mask], scores[mask]
    end
end


# Length methods
length(index::NaiveIndex) = size(index.data, 2)

length(index::BruteTreeIndex) = length(index.tree.data)

length(index::KDTreeIndex) = length(index.tree.data)

length(index::HNSWIndex) = length(index.tree.data)
