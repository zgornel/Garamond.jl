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

#TODO(Corneliu) Add support for other indexing parameters
    # IVFADCIndex(data::Matrix{T};
    #             kc::Int=DEFAULT_COARSE_K,
    #             k::Int=DEFAULT_QUANTIZATION_K,
    #             m::Int=DEFAULT_QUANTIZATION_M,
    #             coarse_quantizer::Symbol=DEFAULT_COARSE_QUANTIZER,
    #             coarse_distance::Distances.PreMetric=DEFAULT_COARSE_DISTANCE,
    #             quantization_distance::Distances.PreMetric=DEFAULT_QUANTIZATION_DISTANCE,
    #             quantization_method::Symbol=DEFAULT_QUANTIZATION_METHOD,
    #             coarse_maxiter::Int=DEFAULT_COARSE_MAXITER,
    #             quantization_maxiter::Int=DEFAULT_QUANTIZATION_MAXITER,
    #             index_type::Type{I}=UInt32
    #
IVFIndex(data::AbstractMatrix) = IVFIndex(IVFADCIndex(data))

IVFIndex(data::SparseMatrixCSC{T,I}) where {T<:AbstractFloat, I<:Integer} =
    IVFIndex(IVFADCIndex(Matrix{T}(data)))


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
