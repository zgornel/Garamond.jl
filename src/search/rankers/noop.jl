"""
Noop ranker, does not rank, returns the first input argument unchanged.
"""
noop_ranker(idxs, args...; kwargs...) = begin
    @debug "Noop ranker, pass through..."
    idxs
end
