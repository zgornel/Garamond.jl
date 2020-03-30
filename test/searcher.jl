@testset "Searcher: build, utils" begin
    local cfg
    for config in CONFIG_FUNCTIONS
        cfg = mktemp() do path, io  # write and parse config file on-the-fly
                   write(io, eval(config)())
                   flush(io)
                   parse_configuration(path)
               end
    end
    # Load data and check primary id
    dbdata = cfg.data_loader()

    # Build embedders
    embedders = [Garamond.build_embedder(dbdata,
                                         embdr_config;
                                         vectors_eltype=cfg.vectors_eltype,
                                         id_key=cfg.id_key)
                 for embdr_config in cfg.embedder_configs]

    # Build searchers
    searchers = [Garamond.build_searcher(dbdata,
                                         embedders,
                                         srcher_config;
                                         id_key=cfg.id_key)
                 for srcher_config in cfg.searcher_configs]
    @test searchers isa Vector{<:AbstractSearcher{eval(cfg.vectors_eltype)}}

    for srcher in searchers
        @test srcher.config.id == id(srcher)
        @test srcher.config.description == description(srcher)
    end

    idx_searcher = 1
    disable!(searchers[idx_searcher])
    @test !isenabled(searchers[idx_searcher])
    enable!(searchers[idx_searcher])
    @test isenabled(searchers[idx_searcher])
end
