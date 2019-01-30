##################################################
# Search model structures and associated methods #
##################################################
"""
Naive model type for storing text embeddings. It is a wrapper
around a matrix of embeddings and performs brute search using
the cosine similarity between vectors.
"""
struct NaiveEmbeddingModel{E, A<:AbstractMatrix{E}} <: AbstractSearchModel
    data::A
end


"""
BruteTree model type for storing text embeddings. It is a wrapper
around a `BruteTree` NN structure and performs brute search using
a distance-based similarity between vectors.
"""
struct BruteTreeEmbeddingModel{A,D} <: AbstractSearchModel
    tree::BruteTree{A,D}  # Array, Distance and Element types
end

BruteTreeEmbeddingModel(data::AbstractMatrix) =
    BruteTreeEmbeddingModel(BruteTree(data))

BruteTreeEmbeddingModel(data::SparseMatrixCSC{T,I}
        ) where {T<:AbstractFloat, I<:Integer} =
    BruteTreeEmbeddingModel(Matrix{T}(data))


"""
K-D Tree model type for storing text embeddings. It is a wrapper
around a `KDTree` NN structure and performs a more efficient
search using a distance-based similarity between vectors.
"""
struct KDTreeEmbeddingModel{A,D} <: AbstractSearchModel
    tree::KDTree{A,D}
end

KDTreeEmbeddingModel(data::AbstractMatrix) =
    KDTreeEmbeddingModel(KDTree(data))

KDTreeEmbeddingModel(data::SparseMatrixCSC{T,I}
        ) where {T<:AbstractFloat, I<:Integer} =
    KDTreeEmbeddingModel(Matrix{T}(data))


"""
HNSW model type for storing text embeddings. It is a wrapper around a
`HierarchicalNSW` (Hierarchical Navigable Small Worlds [1]) NN graph
structure and performs a very efficient search using a distance-based
similarity between vectors.
[1] Yu. A. Malkov, D.A. Yashunin "Efficient and robust approximate nearest
    neighbor search using Hierarchical Navigable Small World graphs"
    (https://arxiv.org/abs/1603.09320)
"""
struct HNSWEmbeddingModel{I,E,A,D} <: AbstractSearchModel
    tree::HierarchicalNSW{I,E,A,D}
end

HNSWEmbeddingModel(data::AbstractMatrix{T}) where T<:AbstractFloat = begin
    _data = [data[:,i] for i in 1:size(data,2)]
    hnsw = HierarchicalNSW(_data;
                           efConstruction=100,
                           M=16,
                           ef=50)
    add_to_graph!(hnsw)
    return HNSWEmbeddingModel(hnsw)
end


# Nearest neighbor search methods
"""
    search(model, point, k)

Searches for the `k` nearest neighbors of `point` in data contained in
the `model`. The model may vary from a simple wrapper inside a matrix
to more complex structures such as k-d trees, etc.
"""
function search(model::NaiveEmbeddingModel{E,A}, point::Vector{E}, k::Int) where
        {E<:AbstractFloat, A<:AbstractMatrix{E}}
    # Cosine similarity
    scores = (model.data)'*point
    idxs = sortperm(scores, rev=true)[1:k]
    return (idxs, scores[idxs])
end

function search(model::BruteTreeEmbeddingModel{A,D}, point::AbstractVector, k::Int) where
        {A<:AbstractArray, D<:Metric}
    # Uses Euclidean distance by default
    idxs, scores = knn(model.tree, point, k, true)
    return idxs, scores
end

function search(model::KDTreeEmbeddingModel{A,D}, point::AbstractVector, k::Int) where
        {A<:AbstractArray, D<:Metric}
    # Uses Euclidean distance by default
    idxs, scores = knn(model.tree, point, k, true)
    return idxs, scores
end

function search(model::HNSWEmbeddingModel{I,E,A,D}, point::AbstractVector, k::Int) where
        {I<:Unsigned, E<:Real, A<:AbstractArray, D<:Metric}
    # Uses Euclidean distance by default
    idxs, scores = knn_search(model.tree, point, k)
    return Int.(idxs), scores
end


# Length methods
length(model::NaiveEmbeddingModel) = size(model.data, 2)

length(model::BruteTreeEmbeddingModel) = length(model.tree.data)

length(model::KDTreeEmbeddingModel) = length(model.tree.data)

length(model::HNSWEmbeddingModel) = length(model.tree.data)
