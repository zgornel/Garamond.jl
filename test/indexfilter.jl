T = Float32
_pkey = :z
n = 10
tbl = table((x=rand(T, n),
             y=rand(T, n),
             z=collect(Int, 1:n),
             xx=vcat(ones(T, round(Int, n/2)),
                     zeros(T, round(Int, n/2))),
             zz=[randstring(2) for _ in 1:n]),
            pkey=_pkey)
nds = ndsparse(deepcopy(tbl))

@testset "DB: filtering, sorting" begin
    all_ids = collect(Int, 1:n)
    no_ids = Int[]
    # Test many missing, empty values
    @test indexfilter(tbl, Dict(), id_key=_pkey) == all_ids
    @test indexfilter(tbl, Dict(), sort_keys=(), id_key=_pkey) == all_ids
    @test indexfilter(tbl, Dict(), sort_keys=(), id_key=:UNK) == no_ids
    @test indexfilter(tbl, Dict(), sort_keys=(:UNK, :UNK2), id_key=_pkey) == all_ids
    @test indexfilter(tbl, Dict(), sort_keys=(:x,), id_key=_pkey) == sortperm(columns(tbl, :x))
    @test indexfilter(tbl, Dict(:missing=>1), sort_keys=(), id_key=_pkey) == all_ids
    @test indexfilter(tbl, Dict(:missing=>1), id_key=_pkey) == all_ids

    # Test interval filters
    @test indexfilter(tbl, Dict(:z=>[1,5]), id_key=_pkey) == collect(1:5)
    @test indexfilter(tbl, Dict(:z=>[1,5]), sort_keys=(), id_key=_pkey) == collect(1:5)
    @test indexfilter(tbl, Dict(:z=>[1,5]), sort_keys=(:z,), id_key=_pkey) == collect(1:5)
    @test indexfilter(tbl, Dict(:z=>[1,5]), sort_keys=(:z,), sort_reverse=true, id_key=_pkey) == collect(5:-1:1)
    # Test sort_keys isa Vector
    @test indexfilter(tbl, Dict(:z=>[1,5]), sort_keys=[:z], sort_reverse=true, id_key=_pkey) == collect(5:-1:1)

    _xcol = columns(tbl, :x)
    _zcol = columns(tbl, :z)

    # Test exact value filters
    tidx = rand(1:n)
    @test indexfilter(tbl, Dict(:z=>_zcol[tidx]), id_key=_pkey) == [tidx]
    @test indexfilter(tbl, Dict(:z=>_zcol[tidx]), sort_keys=(:z,), id_key=_pkey) == [tidx]
    tidx = rand(1:n)
    @test indexfilter(tbl, Dict(:x=>_xcol[tidx]), id_key=_pkey) == [tidx]
    @test indexfilter(tbl, Dict(:x=>_xcol[tidx]), sort_keys=(:z,), id_key=_pkey) == [tidx]

    # Test set values filters
    tidxs = unique([rand(1:n) for _ in 1:5])
    @test indexfilter(tbl, Dict(:z=>Tuple(tidxs)), sort_keys=(:z,), sort_reverse=true, id_key=_pkey) == sort(tidxs, rev=true)

    # Test set value filters, different sort key
    idxs = indexfilter(tbl, Dict(:z=>(1,2,5,7)), sort_keys=(:x,), sort_reverse=true, id_key=_pkey)
    _zord = _zcol[sortperm(_xcol, rev=true)]
    @test idxs == filter(in([1,2,5,7]), _zord)
end
