@testset "Index: $IndexType" for IndexType in [NaiveIndex, BruteTreeIndex, KDTreeIndex, HNSWIndex, IVFIndex]
    data = eltype(1.0)[0 0 0 5 5 5; 0 1 2 10 11 12]
    spdata = sparse(data)
    point = eltype(data)[5.1, 10]
    true_length = size(data, 2)

    if IndexType === IVFIndex
        _idxfunc = d->IVFIndex(d; kc=4, k=2, m=1)
        idx = _idxfunc(data)
        spidx = _idxfunc(spdata)
    else
        idx = IndexType(data)
        spidx = IndexType(data)
    end
    @test idx isa IndexType
    idxs, scores = Garamond.knn_search(idx, point, 10; w=4)
    @test idxs isa Vector{Int} && all(i in idxs for i in 1:true_length)
    @test scores isa Vector{eltype(data)}

    @test length(idx) == length(spidx) == true_length

    # Test not implemented interface
    @test_throws Garamond.IndexOperationException pop!(idx)
    @test_throws Garamond.IndexOperationException push!(idx)
    @test_throws Garamond.IndexOperationException pushfirst!(idx)
    @test_throws Garamond.IndexOperationException popfirst!(idx)
    @test_throws Garamond.IndexOperationException Garamond.delete_from_index!(idx, [1,2])

end
