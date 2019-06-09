"""
Naive index type for storing text embeddings. It is a wrapper
around a matrix of embeddings and performs brute search using
the cosine similarity between vectors.
"""
struct NaiveIndex{E, A<:AbstractMatrix{E}} <: AbstractIndex
    data::A
end


# Nearest neighbor search method
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


# Length method
length(index::NaiveIndex) = size(index.data, 2)
