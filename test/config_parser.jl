const CONFIGS = [:generate_sample_config_1,
                 :generate_sample_config_2]


function test_nt_props(nt, validator)
    propnames = propertynames(nt)
    @assert isempty(symdiff(keys(validator), propnames))
    for (pname, ptype) in validator
        @assert pname in propnames
        @assert getproperty(nt, pname) isa ptype
    end
    true
end

@testset "Config parser: $config" for config in CONFIGS
	cfg = mktemp() do path, io  # write and parse config file on-the-fly
               write(io, eval(config)())
			   flush(io)
			   parse_configuration(path)
		   end
    @test cfg isa NamedTuple

    ENVCONFIG_PROPS = Dict(:data_loader => Function,
                           :data_sampler => Function,
                           :id_key => Symbol,
                           :vectors_eltype => Type,
                           :searcher_configs => Vector,
                           :config_path => String)
    @test test_nt_props(cfg, ENVCONFIG_PROPS)

    SEARCHERCONFIG_PROPS = Dict(:id => Garamond.StringId,
                                :id_aggregation => Garamond.StringId,
                                :description => String,
                                :enabled => Bool,
                                :indexable_fields => Vector{Symbol},
                                :language => String,
                                :stem_words => Bool,
                                :ngram_complexity => Int,
                                :vectors => Symbol,
                                :vectors_transform => Symbol,
                                :vectors_dimension => Int,
                                :search_index => Symbol,
                                :search_index_arguments => Vector{Any},
                                :search_index_kwarguments => Dict{Symbol, Any},
                                :embeddings_path => Union{Nothing, String},
                                :embeddings_kind => Symbol,
                                :doc2vec_method => Symbol,
                                :glove_vocabulary => Union{Nothing, String},
                                :oov_policy => Symbol,
                                :embedder_kwarguments => Dict{Symbol, Any},
                                :heuristic => Union{Nothing, Symbol},
                                :text_strip_flags => UInt32,
                                :query_strip_flags => UInt32,
                                :sif_alpha => cfg.vectors_eltype,
                                :borep_dimension => Int,
                                :borep_pooling_function => Symbol,
                                :disc_ngram => Int,
                                :score_alpha => cfg.vectors_eltype,
                                :score_weight => cfg.vectors_eltype)
    for sc in cfg.searcher_configs
        @test test_nt_props(sc, SEARCHERCONFIG_PROPS)
    end
end
