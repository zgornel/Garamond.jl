"""
Naive index type for storing vectors. It is a wrapper
around a vector of embeddings and performs brute search using
the cosine similarity between vectors.
"""
struct NaiveIndex{E, A<:Vector{<:AbstractVector{E}}} <: Garamond.AbstractIndex
    data::A
end

NaiveIndex(data, args...; kwargs...) =
    NaiveIndex([densify(collect(c)) for c in eachcol(data)])  # args, kwargs are ignored


# Nearest neighbor search method
function knn_search(index::NaiveIndex{E},
                    point::AbstractVector,
                    k::Int,
                    keep::Vector{Int}=collect(1:length(index));
                    kwargs...
                   ) where {E<:AbstractFloat}
    n = length(keep)
    _k = min(n, k)
    scores = zeros(E, n)
    _point = densify(point)'
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


# push!, pushfirst!, pop!, popfirst!, delete_from_index!
Base.push!(index::NaiveIndex, point) = push!(index.data, point)

Base.pushfirst!(index::NaiveIndex, point) = pushfirst!(index.data, point)

Base.pop!(index::NaiveIndex) = pop!(index.data)

Base.popfirst!(index::NaiveIndex) = popfirst!(index.data)

delete_from_index!(index::NaiveIndex, pos) = begin
    deleteat!(index.data, pos)
    nothing
end
