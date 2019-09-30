####################
#  TODO(corneliu):
#  - add support for a rerank-er based on IDs or linear indices
#  - the reranker should be a small TCP server that reads a list
#  of IDs/IDXs (an array of numers) and returns a result similar to
#  the search: tuple of the same idxs/IDs sent and a vectors of their
#  scores i.e. ([1,15,23,..,10], [0.1, 0.023, 0.45, ..., 1])
#                ^^^ indices       ^^^ corresponding scores
####################
####################
noop_ranker(results, args...; kwargs...) = begin
    @debug "Noop ranker, returning the same results..."
    results
end
