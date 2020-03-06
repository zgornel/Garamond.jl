"""
Noop index type for storing vectors. Returns empty vectors of indexes, scores.
Useful when search is done only in the db.
"""
struct NoopIndex{E} <: Garamond.AbstractIndex
    length::Int
end

NoopIndex(data::AbstractMatrix{E}) where {E<:AbstractFloat} = NoopIndex{E}(size(data,2))


# Nearest neighbor search method
function knn_search(index::NoopIndex{E},
                    point::AbstractVector,
                    k::Int,
                    keep::Vector{Int}=collect(1:length(index));
                    kwargs...
                   ) where {E<:AbstractFloat}
    Vector{Int}(), Vector{E}()
end


# Length method
length(index::NoopIndex) = index.length


# push!, pushfirst!, pop!, popfirst!, delete_from_index!
Base.push!(index::NoopIndex, point) = nothing

Base.pushfirst!(index::NoopIndex, point) = nothing

Base.pop!(index::NoopIndex) = nothing

Base.popfirst!(index::NoopIndex) = nothing

delete_from_index!(index::NoopIndex, pos) = nothing
