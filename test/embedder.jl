@testset "Embedder: build, embed" begin
    cfg_symbol = CONFIG_FUNCTIONS[1]
	cfg = mktemp() do path, io  # write and parse config file on-the-fly
               write(io, eval(cfg_symbol)())
			   flush(io)
			   parse_configuration(path)
		   end
    dbdata = cfg.data_loader()
    _embeddable_fields = cfg.embedder_configs[1].embeddable_fields
    _embedder_kwarguments = Dict{Symbol,Any}()
    T = eval(cfg.vectors_eltype)
    entries = [(field1=1000, field2="2000"), (field1="not_embeddable",)]  # 2 documents
    fields = [:field1, :field2]

    for _vectors in [:count, :tf, :tfidf, :bm25]
        for _vectors_transform in [:none, :rp, :lsa]
            for _vectors_dimension in [5, 1000]
                for _oov_policy in [:none, :large_vector]
                    config = (id="id",
                              description="",
                              language="english",
                              stem_words=false,
                              ngram_complexity=1,
                              vectors=_vectors,
                              vectors_transform=_vectors_transform,
                              vectors_dimension=_vectors_dimension,
                              #embeddings_path=_embeddings_path,
                              #embeddings_kind=_embeddings_kind,
                              #doc2vec_method=_doc2vec_method,
                              #glove_vocabulary=_glove_vocabulary,
                              oov_policy=_oov_policy,
                              embedder_kwarguments=_embedder_kwarguments,
                              embeddable_fields=_embeddable_fields,
                              text_strip_flags=UInt32(0),
                              #sif_alpha=_sif_alpha,
                              #borep_dimension=_borep_dimension,
                              #borep_pooling_function=_borep_pooling_function,
                              #disc_ngram=_disc_ngram
                             )
                    embedder = Garamond.build_embedder(dbdata, config; vectors_eltype=T, id_key=cfg.id_key)
                    @test embedder isa AbstractEmbedder{T}
                    embedded, isembedded = embed(embedder, entries; fields=fields)
                    @test embedded isa SparseMatrixCSC{T,Int}
                    @test isembedded isa BitArray
                    @test isembedded[1] == true && isembedded[2] == false
                end
            end
        end
    end

    root_path = "/" * joinpath(split(pathof(Garamond), "/")[1:end-2]...)
    VECTORS = [:word2vec, :word2vec, :glove, :conceptnet, :compressed, :compressed]
    EMBEDDINGS_KINDS = [:binary, :text, :text, :text, :binary, :text]
    EMBEDDINGS_PATHS = [joinpath(root_path, "test", "embeddings", "word2vec", "sample_model.bin"),
                        joinpath(root_path, "test", "embeddings", "word2vec", "sample_model.txt"),
                        joinpath(root_path, "test", "embeddings", "glove", "sample_model.txt"),
                        joinpath(root_path, "test", "embeddings", "conceptnet", "sample_model.txt"),
                        joinpath(root_path, "test", "embeddings", "compressed", "sample_model.bin"),
                        joinpath(root_path, "test", "embeddings", "compressed", "sample_model.txt")]
    for (_vectors, _embeddings_path, _embeddings_kind) in zip(VECTORS, EMBEDDINGS_PATHS, EMBEDDINGS_KINDS)
        for _doc2vec_method in [:boe, :sif, :borep, :cpmean, :disc]
            for _oov_policy in [:none, :large_vector]
                config = (id="id",
                          description="",
                          language="english",
                          stem_words=false,
                          #ngram_complexity=1,
                          vectors=_vectors,
                          #vectors_transform=_vectors_transform,
                          #vectors_dimension=_vectors_dimension,
                          embeddings_path=_embeddings_path,
                          embeddings_kind=_embeddings_kind,
                          doc2vec_method=_doc2vec_method,
                          glove_vocabulary="",
                          oov_policy=_oov_policy,
                          embedder_kwarguments=_embedder_kwarguments,
                          embeddable_fields=_embeddable_fields,
                          text_strip_flags=UInt32(0),
                          sif_alpha=Garamond.DEFAULT_SIF_ALPHA,
                          borep_dimension=Garamond.DEFAULT_BOREP_DIMENSION,
                          borep_pooling_function=Garamond.DEFAULT_BOREP_POOLING_FUNCTION,
                          disc_ngram=Garamond.DEFAULT_DISC_NGRAM
                         )
                embedder = Garamond.build_embedder(dbdata, config; vectors_eltype=T, id_key=cfg.id_key)
                @test embedder isa AbstractEmbedder{T}
                embedded, isembedded = embed(embedder, entries; fields=fields)
                @test embedded isa Matrix{T}
                @test Garamond.dimensionality(embedder) == size(embedded, 1)
                @test isembedded isa BitArray
                @test isembedded[1] == true && isembedded[2] == false
            end
        end
    end
end
