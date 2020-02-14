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

    # db_push!
    _len = length(tbl)
    data = (x=T(-100.0), y=T(-11.1), z=_len+1)
    @test Garamond.db_push!(tbl, data; id_key=_pkey) == nothing && length(tbl) == _len + 1
    @test Garamond.db_push!(nds, data; id_key=_pkey) == nothing && length(nds) == _len + 1
    #@test_throws ErrorException Garamond.db_push!(tbl, data)
    #@test_throws ErrorException Garamond.db_push!(nds, data)
    wrong_data = [(x=T(0.0), y=-T(11.0), z=100),         # wrong pkey
                  (x="a", y=T(1.0), z=_len+1),        # wrong eltype
                  (x=T(1.0), y=T(2.0), z=_len+1, γ="a"), # additional column
                  (x=T(1.0), y=T(2.0))]                  # missing column
    for wrong in wrong_data
        @test_throws ErrorException Garamond.db_push!(tbl, wrong; id_key=_pkey)
        @test_throws ErrorException Garamond.db_push!(nds, wrong; id_key=_pkey)
    end

    # db_pushfirst!
    _len = length(tbl)
    data = (x=T(-100.0), y=T(-11.1), z=1)
    @test Garamond.db_pushfirst!(tbl, data; id_key=_pkey) == nothing && length(tbl) == _len + 1
    @test getproperty(columns(tbl), _pkey) == collect(1:_len+1)
    @test Garamond.db_pushfirst!(nds, data; id_key=_pkey) == nothing && length(nds) == _len + 1
    @test getproperty(columns(nds), _pkey) == collect(1:_len+1)
    #@test_throws ErrorException Garamond.db_pushfirst!(tbl, data)
    #@test_throws ErrorException Garamond.db_pushfirst!(nds, data)
    wrong_data = [(x=T(0.0), y=-T(11.0), z=100),         # wrong pkey
                  (x="a", y=T(1.0), z=_len+1),        # wrong eltype
                  (x=T(1.0), y=T(2.0), z=_len+1, γ="a"), # additional column
                  (x=T(1.0), y=T(2.0))]                  # missing column
    for wrong in wrong_data
        @test_throws ErrorException Garamond.db_pushfirst!(tbl, wrong; id_key=_pkey)
        @test_throws ErrorException Garamond.db_pushfirst!(nds, wrong; id_key=_pkey)
    end

    # db_pop!
    _len = length(tbl)
    last_row_tbl = last(rows(tbl))
    last_row_nds = last(rows(nds))
    @test Garamond.db_pop!(tbl) == last_row_tbl && length(tbl) == _len - 1
    @test Garamond.db_pop!(nds) == last_row_nds && length(nds) == _len - 1

    # db_popfirst!
    _len = length(tbl)
    first_row_tbl = first(rows(tbl))
    first_row_nds = first(rows(nds))
    @test Garamond.db_popfirst!(tbl; id_key=_pkey) == first_row_tbl && length(tbl) == _len - 1
    @test getproperty(columns(tbl), _pkey) == collect(1:_len-1)
    @test Garamond.db_popfirst!(nds; id_key=_pkey) == first_row_nds && length(nds) == _len - 1
    @test getproperty(columns(nds), _pkey) == collect(1:_len-1)

    # db_deleteat!
    _len = length(tbl)
    to_delete = sort(unique(rand(1:_len, 3)))
    @test Garamond.db_deleteat!(tbl, to_delete; id_key=_pkey) == nothing &&
        length(tbl) == _len - length(to_delete)
    @test getproperty(columns(tbl), _pkey) == collect(1:(_len-length(to_delete)))
    @test Garamond.db_deleteat!(nds, to_delete; id_key=_pkey) == nothing &&
        length(nds) == _len - length(to_delete)
    @test getproperty(columns(nds), _pkey) == collect(1:(_len-length(to_delete)))

    # db_drop_columns
    @test Garamond.db_drop_columns(tbl, [:does_not_exist]) == tbl
    @test Garamond.db_drop_columns(nds, [:does_not_exist]) == nds
    @test !in(_pkey, colnames(Garamond.db_drop_columns(tbl, [_pkey])))
    @test Garamond.db_drop_columns(nds, [_pkey]) == nds  # cannot drop index
    dropped_x = Garamond.db_drop_columns(tbl, [:x])
    @test !(:x in colnames(dropped_x))
    dropped_x = Garamond.db_drop_columns(tbl, [:x])
    @test !(:x in colnames(dropped_x))
end
