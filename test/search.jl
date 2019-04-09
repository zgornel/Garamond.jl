println("Running search tests (this make take a while...)")
# Test search
PARSERS = [:delimited_format_1, :directory_format_1]

# Loop over parsers and search types
for parser in PARSERS
    data_path = generate_test_data(parser)
    config_path = generate_test_confs(data_path, parser)
    configs = readdir(config_path)
    n = length(configs)
    failed_configs = String[]
    @testset "SEARCH: parser=$parser" begin
        for (i, path) in enumerate(configs)
            local srchers  # the searchers
            #try
                srchers = load_searchers(joinpath(config_path, path))
            #catch
            #    @test_broken false
            #    continue
            #end
            # Initialize search parameters
            SM = [:exact, :regex]
            MAX_SUGGESTIONS=[0, 5]
            needles = [randstring(rand([1,2,3])) for _ in 1:3]
            # Loop over minor search options
            for search_method in SM
                for max_suggestions in MAX_SUGGESTIONS
                    # Do one search (skipping non-relevant cases)
                    if search_method == :regex &&
                            srchers[1].config.vectors in [:word2vec, :conceptnet, :glove]
                        continue
                    else
                        search(srchers, needles,
                               max_suggestions=max_suggestions,
                               search_method=search_method)
                    end
                end
            end
            @test true
        end
    end
    # Cleanup
    rm(data_path, recursive=true, force=true)
    rm(config_path, recursive=true, force=true)
    println("Cleanup complete.")
end
