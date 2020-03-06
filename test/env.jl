@testset "Environment: creation" begin
    # Basic
    for gfunc in [generate_sample_config_1, generate_sample_config_2]
        cfg = mktemp() do path, io
            write(io, gfunc())
            flush(io)
            parse_configuration(path)
        end
        @test build_search_env(cfg) isa Garamond.SearchEnv
    end
end


make_entry(;id=1) = (id=id,
                     IntField=1, FloatField=0.01,
                     StringField="a", StringField2="b",
                     RandFloat=0.0, RandString="c")


@testset "Environment: push!/pop! primitives" begin
    cfg = mktemp() do path, io
        write(io, generate_sample_config_2())
        flush(io)
        parse_configuration(path)
    end
    for index_type in [:naive, :brutetree, :kdtree, :hnsw, :ivfadc]
        for sc in cfg.searcher_configs
            sc.search_index = index_type
        end
        try
            env = build_search_env(cfg)
            initial_length = length(env.dbdata)
            index_length(x) = length(x.index)
            get_vec_type(env::Garamond.SearchEnv{T}) where {T} = T

            @test env isa Garamond.SearchEnv
            if index_type in [:naive, :brutetree, :ivfadc]  # push!/pop! supported
                # push!
                ientry = make_entry(id=initial_length+1)
                push!(env, ientry)
                @test all(length(env.dbdata) .== map(index_length, env.searchers))
                @test length(env.dbdata) == initial_length + 1

                # pop!
                oentry, embedded = pop!(env, make_entry)
                @test all(length(env.dbdata) .== map(index_length, env.searchers))
                @test length(env.dbdata) == initial_length
                index_type !== :ivfadc && @test ientry == oentry
                @test embedded isa Vector{get_vec_type(env)}

                # pushfirst!
                ientry = make_entry(id=1)
                pushfirst!(env, ientry)
                @test all(length(env.dbdata) .== map(index_length, env.searchers))
                @test length(env.dbdata) == initial_length + 1

                # popfirst!
                oentry, embedded = popfirst!(env, make_entry)
                @test all(length(env.dbdata) .== map(index_length, env.searchers))
                @test length(env.dbdata) == initial_length
                index_type !== :ivfadc && @test ientry == oentry
                @test embedded isa Vector{get_vec_type(env)}

                # deleteat!
                deleteat!(env, [1])
                @test all(length(env.dbdata) .== map(index_length, env.searchers))
                @test length(env.dbdata) == initial_lengthi - 1
            else
                # push!
                ientry = make_entry(id=initial_length+1)
                push!(env, ientry)
                @test all(length(env.dbdata) .== map(index_length, env.searchers))
                @test length(env.dbdata) == initial_length

                # pop!
                oentry = pop!(env)  # returns a nothing
                @test oentry === nothing
                @test all(length(env.dbdata) .== map(index_length, env.searchers))
                @test length(env.dbdata) == initial_length

                # pushfirst!
                ientry = make_entry(id=1)
                pushfirst!(env, ientry)
                @test all(length(env.dbdata) .== map(index_length, env.searchers))
                @test length(env.dbdata) == initial_length
                @test embedded isa Vector{get_vec_type(env)}

                # popfirst!
                oentry = popfirst!(env)  # returns a nothing
                @test oentry === nothing
                @test all(length(env.dbdata) .== map(index_length, env.searchers))
                @test length(env.dbdata) == initial_length

                # deleteat!
                deleteat!(env, [1])
                @test all(length(env.dbdata) .== map(index_length, env.searchers))
                @test length(env.dbdata) == initial_length
            end
        catch
        end
    end
end
