"""
Naive index type for storing text embeddings. It is a wrapper
around a matrix of embeddings and performs brute search using
the cosine similarity between vectors.

It does not however use matrix multiplication but element-wise
multiplication and hence is fast for sparse vectors and matrices.

The search algorithm requires elements of DTVs be associated
with terms in a lexicon and hence, transforming the vectors
through random projections, LSA etc. prior to search will
yield wrong results.
"""
struct NaiveFastIndex{E, A<:AbstractMatrix{E}} <: AbstractIndex
    data::A
end


# Nearest neighbor search method
function knn_search(index::Garamond.NaiveFastIndex{E,A},
                    point::AbstractVector,
                    k::Int,
                    keep::Vector{Int}=collect(1:length(index))
                   ) where {E<:AbstractFloat, A<:AbstractMatrix{E}}
    n = length(keep)
    scores = zeros(E, n)
    inds = findall(>(0), point)
    _M = view(index.data, inds, keep)
    @inbounds for i in eachindex(keep)
        for j in eachindex(inds)
            if _M[j, i] != 0.0
                scores[i]+= _M[j, i] * point[inds[j]]
            end
        end
    end
    order = sortperm(scores, rev=true)
    _k = min(n, k)
    return keep[order[1:_k]], one(E) .- scores[order[1:_k]]
end


# Length method
length(index::NaiveFastIndex) = size(index.data, 2)
