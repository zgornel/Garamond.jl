rerank!(::Nothing, results) = results

rerank!(ranker, results) = begin
    @warn "Re-ranking not implemented, returning the same results..."
    results
end
