using Garamond
using JuliaDB

T = Float32
_pkey = :z
tbl = table((x=rand(T, 10), y=rand(T, 10), z=collect(Int, 1:10)), pkey=_pkey)
nds = ndsparse(deepcopy(tbl))

@testset "DB: id_key checks, push/pop primitives" begin
    # db_create_schema
    @test sort(Garamond.db_create_schema(tbl), by=x->x.column)  ==
          sort(Garamond.db_create_schema(nds), by=x->x.column)  ==
          [(column=:x, coltype=T, pkey=false),
           (column=:y, coltype=T, pkey=false),
           (column=_pkey, coltype=Int, pkey=true)]


    # db_get_primary_keys
    @test Garamond.db_get_primary_keys(tbl) == Garamond.db_get_primary_keys(nds) == (_pkey,)


    # db_check_id_key
    @test Garamond.db_check_id_key(tbl, _pkey) == Garamond.db_check_id_key(nds, _pkey) == nothing
    @test_throws ErrorException Garamond.db_check_id_key(tbl, :some_random_key)
    @test_throws ErrorException Garamond.db_check_id_key(nds, :some_random_key)
    @test_throws ErrorException Garamond.db_check_id_key(tbl, :x)
    @test_throws ErrorException Garamond.db_check_id_key(nds, :x)


    # db_select_entry
    @test Garamond.db_select_entry(tbl, 1; id_key=_pkey) == first(rows(tbl))
    @test Garamond.db_select_entry(nds, 1; id_key=_pkey) == first(rows(nds))
    _tbl = Garamond.db_select_entry(tbl, 1_000; id_key=_pkey)
    @test _tbl isa IndexedTable && isempty(_tbl)
    _nds = Garamond.db_select_entry(nds, 1_000; id_key=_pkey)
    @test _nds isa NDSparse && isempty(_nds)


    # push!
    _len = length(tbl)
    data = (x=-100.0, y=-11.1, z=_len+1)
    @test push!(tbl, data; id_key=_pkey) == nothing && length(tbl) == _len + 1
    @test push!(nds, data; id_key=_pkey) == nothing && length(nds) == _len + 1
    #@test_throws ErrorException push!(tbl, data)
    #@test_throws ErrorException push!(nds, data)
    wrong_data = [(x=0.0, y=-11.0, z=100),         # wrong pkey
                  (x="a", y=1.0, z=_len+1),        # wrong eltype
                  (x=1.0, y=2.0, z=_len+1, γ="a"), # additional column
                  (x=1.0, y=2.0)]                  # missing column
    for wrong in wrong_data
        @test_throws ErrorException push!(tbl, wrong; id_key=_pkey)
        @test_throws ErrorException push!(nds, wrong; id_key=_pkey)
    end


    # pushfirst!
    _len = length(tbl)
    data = (x=-100.0, y=-11.1, z=1)
    @test pushfirst!(tbl, data; id_key=_pkey) == nothing && length(tbl) == _len + 1
    @test getproperty(columns(tbl), _pkey) == collect(1:_len+1)
    @test pushfirst!(nds, data; id_key=_pkey) == nothing && length(nds) == _len + 1
    @test getproperty(columns(nds), _pkey) == collect(1:_len+1)
    #@test_throws ErrorException pushfirst!(tbl, data)
    #@test_throws ErrorException pushfirst!(nds, data)
    wrong_data = [(x=0.0, y=-11.0, z=2),      # wrong pkey
                  (x=1.0, y=2.0)]             # missing column
    for wrong in wrong_data
        @test_throws ErrorException pushfirst!(tbl, wrong; id_key=_pkey)
        @test_throws ErrorException pushfirst!(nds, wrong; id_key=_pkey)
    end
    @test_throws MethodError pushfirst!(tbl, (x="a", y=1.0, z=1); id_key=_pkey)  # wrong eltype
    @test_throws MethodError pushfirst!(nds, (x="a", y=1.0, z=1); id_key=_pkey)  # wrong eltype


    # pop!
    _len = length(tbl)
    last_row_tbl = last(rows(tbl))
    last_row_nds = last(rows(nds))
    @test pop!(tbl) == last_row_tbl && length(tbl) == _len - 1
    @test pop!(nds) == last_row_nds && length(nds) == _len - 1


    # popfirst!
    _len = length(tbl)
    first_row_tbl = first(rows(tbl))
    first_row_nds = first(rows(nds))
    @test popfirst!(tbl; id_key=_pkey) == first_row_tbl && length(tbl) == _len - 1
    @test getproperty(columns(tbl), _pkey) == collect(1:_len-1)
    @test popfirst!(nds; id_key=_pkey) == first_row_nds && length(nds) == _len - 1
    @test getproperty(columns(nds), _pkey) == collect(1:_len-1)

    # deleteat!
    _len = length(tbl)
    to_delete = sort(unique(rand(1:_len, 3)))
    @test deleteat!(tbl, to_delete; id_key=_pkey) == nothing &&
        length(tbl) == _len - length(to_delete)
    @test getproperty(columns(tbl), _pkey) == collect(1:(_len-length(to_delete)))
    @test deleteat!(nds, to_delete; id_key=_pkey) == nothing &&
        length(tbl) == _len - length(to_delete)
    @test getproperty(columns(nds), _pkey) == collect(1:(_len-length(to_delete)))
end
