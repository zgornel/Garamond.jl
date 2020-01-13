"""
Naive index type for storing text embeddings. It is a wrapper
around a vector of embeddings and performs brute search using
the cosine similarity between vectors.
"""
struct NaiveIndex{E, A<:Vector{<:AbstractVector{E}}} <: Garamond.AbstractIndex
    data::A
end

NaiveIndex(data::AbstractMatrix{E}) where E<:AbstractFloat = begin
    NaiveIndex([data[:,i] for i in 1:size(data,2)])
end


# Nearest neighbor search method
function knn_search(index::NaiveIndex{E},
                    point::AbstractVector,
                    k::Int,
                    keep::Vector{Int}=collect(1:length(index))
                   ) where {E<:AbstractFloat}
    # Turn sparse vectors into dense ones
    __densify(v::AbstractVector) = v
    __densify(v::AbstractSparseVector) = Vector(v)

    n = length(keep)
    _k = min(n, k)
    scores = zeros(E, n)
    _point = __densify(point)'
    # Cosine similarity
    @inbounds for i in eachindex(keep)
        scores[i] = _point * index.data[i]
    end
    #scores = index.data[:, keep]' * __densify(point)
    idxs = sortperm(scores, rev=true)[1:_k]
    return keep[idxs], one(E) .- scores[idxs]
end


# Length method
length(index::NaiveIndex) = length(index.data)
