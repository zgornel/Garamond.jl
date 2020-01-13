"""
Naive index type for storing text embeddings. It is a wrapper
around a vector of embeddings and performs brute search using
the cosine similarity between vectors.

It does not however use matrix multiplication but element-wise
multiplication and hence is fast for sparse vectors and matrices.

The search algorithm requires elements of DTVs be associated
with terms in a lexicon and hence, transforming the vectors
through random projections, LSA etc. prior to search will
yield wrong results.
"""
struct NaiveFastIndex{E, A<:Vector{<:AbstractVector{E}}} <: Garamond.AbstractIndex
    data::A
end

NaiveFastIndex(data::AbstractMatrix{E}) where E<:AbstractFloat = begin
    NaiveFastIndex([data[:,i] for i in 1:size(data,2)])
end

length(index::NaiveFastIndex) = length(index.data)


function knn_search(index::NaiveFastIndex{E},
                    point::AbstractVector,
                    k::Int,
                    keep::Vector{Int}=collect(1:length(index))
                    ) where {E<:AbstractFloat}
    n = length(keep)
    scores = zeros(E, n)
    inds = findall(>(0), point)
    @inbounds for i in eachindex(keep)
        for j in eachindex(inds)
            if index.data[i][inds[j]] != 0.0
                scores[i]+= index.data[i][inds[j]] * point[inds[j]]
            end
        end
    end
    order = sortperm(scores, rev=true)
    _k = min(n, k)
    return keep[order[1:_k]], one(E) .- scores[order[1:_k]]
end
