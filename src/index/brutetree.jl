"""
BruteTree index type for storing vectors. It is a wrapper
around a `BruteTree` NN structure and performs brute search using
a distance-based similarity between vectors.
"""
struct BruteTreeIndex{A,D} <: AbstractIndex
    tree::BruteTree{A,D}  # Array, Distance and Element types
end

BruteTreeIndex(data, args...; kwargs...) = BruteTreeIndex(BruteTree(densify(data), args...; kwargs...))


# Nearest neighbor search method
function knn_search(index::BruteTreeIndex{A,D},
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
length(index::BruteTreeIndex) = length(index.tree.data)

# push!, pushfirst!, pop!, popfirst!, delete_from_index!
Base.push!(index::BruteTreeIndex, point) = push!(index.tree.data, point)

Base.pushfirst!(index::BruteTreeIndex, point) = pushfirst!(index.tree.data, point)

Base.pop!(index::BruteTreeIndex) = pop!(index.tree.data)

Base.popfirst!(index::BruteTreeIndex) = popfirst!(index.tree.data)

delete_from_index!(index::BruteTreeIndex, pos) = begin
    deleteat!(index.tree.data, pos)
    nothing
end
