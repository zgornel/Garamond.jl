##################################################
# Search index structures and associated methods #
##################################################
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
    hnsw = HierarchicalNSW(_data; efConstruction=100, M=16, ef=50)
    add_to_graph!(hnsw)
    return HNSWIndex(hnsw)
end

_build_hnsw_data(data::AbstractMatrix) = [Vector(data[:,i]) for i in 1:size(data,2)]
_build_hnsw_data(data::Matrix) = [data[:,i] for i in 1:size(data,2)]


# Nearest neighbor search method
function knn_search(index::HNSWIndex{I,E,A,D},
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


# Length method
length(index::HNSWIndex) = length(index.tree.data)
