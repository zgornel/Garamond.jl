@testset "Index: $IndexType" for IndexType in [NaiveIndex, BruteTreeIndex, KDTreeIndex, HNSWIndex, IVFIndex]
    data = eltype(1.0)[0 0 0 5 5 5; 0 1 2 10 11 12]
    spdata = sparse(data)
    point = eltype(data)[5.1, 10]
    true_length = size(data, 2)

    if IndexType === IVFIndex
        _indexfunc = d->IVFIndex(d; kc=4, k=2, m=1)
        index = _indexfunc(data)
        spindex = _indexfunc(spdata)
    else
        index = IndexType(data)
        spindex = IndexType(data)
    end
    @test index isa IndexType
    idxs, scores = Garamond.knn_search(index, point, 10; w=4)
    @test idxs isa Vector{Int} && all(i in idxs for i in 1:true_length)
    @test scores isa Vector{eltype(data)}

    @test length(index) == length(spindex) == true_length

    # Test push!, pop! interface
    idx = 1
    point = data[:, idx]
    if IndexType in [NaiveIndex, BruteTreeIndex, IVFIndex]
        @test push!(index, point) === nothing && length(index) == true_length+1
        @test pop!(index) == point && length(index) == true_length
        @test pushfirst!(index, point) === nothing && length(index) == true_length+1
        @test popfirst!(index) == point && length(index) == true_length
        @test Garamond.delete_from_index!(index, [idx]) === nothing && length(index) == true_length-1
    else
        @test_throws MethodError push!(idx, point)
        @test_throws MethodError pushfirst!(idx, point)
        @test_throws MethodError pop!(idx)
        @test_throws MethodError popfirst!(idx)
        @test_throws MethodError Garamond.delete_from_index!(idx, [1,2])
    end
end
