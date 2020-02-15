# Abstract types
abstract type AbstractIndex end


"""
    knn_search(index, point, k, keep)

Searches for the `k` nearest neighbors of `point` in data contained in
the `index`. The index may vary from a simple wrapper inside a matrix
to more complex structures such as k-d trees, etc. Only neighbors
present in `keep` are returned.
"""
function knn_search(index::AbstractIndex,
                    point::AbstractVector,
                    k::Integer,
                    keep::AbstractVector)
    throw(ErrorException("`search` is not implemented for $(typeof(index)) indexes."))
end


"""
    length(index)

Returns the number of points indexed in `index`.
"""
function length(index::AbstractIndex)
    throw(ErrorException("`length` is not implemented for $(typeof(index)) indexes."))
end


#TODO(Corneliu) **cc-indexing** - Add IVFADC support
#TODO(Corneliu) **cc-indexing** - add method prototypes
#TODO(Corneliu) **cc-indexing** - add IndexSearchException exception (thrown whenver cannot search the index)
#TODO(Corneliu) **cc-indexing** - add IndexModificationException exception (thrown whenver one cannot operate with the index)
#TODO(Corneliu) **cc-indexing** - consider removing the KDTree structure - if not, throw exceptions around
#TODO(Corneliu) **cc-indexing** - find way to put more indexing parameters in searcher configs i.e. .garamondrc?
#                                 DEFAULT_METRIC, DEFAULT_HNSW_<several>
