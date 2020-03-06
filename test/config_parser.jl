const CONFIGS = [:generate_sample_config_1,
                 :generate_sample_config_2]
@testset "Config parser: $config" for config in CONFIGS
	cfg = mktemp() do path, io  # write and parse config file on-the-fly
               write(io, eval(config)())
			   flush(io)
			   parse_configuration(path)
		   end
    @test cfg isa NamedTuple

    ALL_PROPS = (:data_loader, :data_streamer, :id_key, :vectors_eltype, :searcher_configs, :config_path)
    for p in propertynames(cfg)
        @test p in ALL_PROPS
    end

end
