##################################################
# Search index structures and associated methods #
##################################################
"""
IVFADC index type for storing vectors. It is a wrapper around a
`IVFADCIndex` (inverted file system with asymmetric distance computation)
structure and performs a billion-scale search using a distance-based
similarity between vectors.

# References
 * [Jègou et al. "Product quantization for nearest neighbor search"](https://hal.inria.fr/file/index/docid/514462/filename/paper_hal.pdf)
 * [Baranchuk et al. "Revisiting the inverted indices for billion-scale approximate nearest neighbors"](http://openaccess.thecvf.com/content_ECCV_2018/papers/Dmitry_Baranchuk_Revisiting_the_Inverted_ECCV_2018_paper.pdf)
"""
struct IVFIndex{U,I,Dc,Dr,T,Q} <: AbstractIndex
    index::IVFADCIndex{U,I,Dc,Dr,T,Q}
end

IVFIndex(data::AbstractMatrix; kwargs...) = IVFIndex(IVFADCIndex(data; kwargs...))

IVFIndex(data::SparseMatrixCSC{T,I}; kwargs...) where {T<:AbstractFloat, I<:Integer} =
    IVFIndex(IVFADCIndex(Matrix{T}(data); kwargs...))


# Nearest neighbor search method
function knn_search(index::IVFIndex{U,I,Dc,Dr,T,Q},
                    point::AbstractVector{T},
                    k::Int,
                    keep::Vector{Int}=collect(1:length(index));
                    w::Int=1
                   ) where {U,I,Dc,Dr,T,Q}
    # Uses Euclidean distance by default
    _idxs, scores = knn_search(index.index, Vector(point), k; w=w)
    idxs = Int.(_idxs) .+ 1
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
length(index::IVFIndex) = length(index.index)


# push!, pushfirst!, pop!, popfirst!, delete_from_index!
Base.push!(index::IVFIndex, point) = push!(index.index, point)

Base.pushfirst!(index::IVFIndex, point) = pushfirst!(index.index, point)

Base.pop!(index::IVFIndex) = pop!(index.index)

Base.popfirst!(index::IVFIndex) = popfirst!(index.index)

delete_from_index!(index::IVFIndex, pos) = begin
    IVFADC.delete_from_index!(index.index, pos)
    nothing
end
