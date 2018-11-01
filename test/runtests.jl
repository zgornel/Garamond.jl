using Test
using Random
using Garamond



# Generates test files in temporary directory
function generate_test_files(parser_config::Symbol, sep::String="|")
    # Make directories
    tmp_path = tempdir()
    test_filepath = abspath(joinpath(tmp_path, "garamond", "test"))
    mkpath(test_filepath)
    # Test for parser configuration option
    if parser_config == :csv_config_1
        nlines = rand([100, 300, 500], 3)  # 3 files, hard fixed by config
        for i in 1:length(nlines)
            filename = joinpath(test_filepath, "test_file_$(i)_csv_format_1.tsv")
            open(filename, "w") do fid
                for _ in 1:nlines[i]
                    line = join([randstring(rand(1:10)) for _ in 1:10], sep)*"\n"
                    write(fid, line)
                end
            end
        end
    else
        @error "Unknown config"
    end
    return test_filepath
end



@testset "Classic search test... (csv_format_1)" begin
    # Generate test files
    test_filepath = generate_test_files(:csv_config_1)
    # Create corpora searches
    # TODO(Corneliu): write config as well
    config_filepath = abspath(joinpath(@__DIR__,
        "test_configurations", ".test_data_config_search_classic"))
    agg_searcher = aggregate_searcher(config_filepath)
    # Initialize search parameters
    _id = StringId("specific_id")
    _id_disabled = "disabled_id"
    ST = [:data, :metadata, :all]
    SM = [:exact, :regex]
    needles = [randstring(rand([1,2,3])) for _ in 1:5]
    MAX_SUGGESTIONS=[0, 5]
    #enable!(agg_searcher, _id_disabled)
    srcher = agg_searcher[_id]
    # Test that the whole thing does not crash
    for search_type in ST
        for search_method in SM
            for max_suggestions in MAX_SUGGESTIONS
                try
                    search(agg_searcher,
                           needles,
                           search_type=search_type,
                           search_method=search_method,
                           max_suggestions=max_suggestions)
                    @test true
                catch
                    @test false
                    rm(test_filepath, recursive=true, force=true)
                end
            end
        end
    end
    # Cleanup
    rm(test_filepath, recursive=true, force=true)
end



@testset "Semantic search test... (csv_format_1)" begin
    # Generate test files
    test_filepath = generate_test_files(:csv_config_1)
    # Create corpora searches
    # TODO(Corneliu): write config as well
    config_filepath = abspath(joinpath(@__DIR__,
        "test_configurations", ".test_data_config_search_semantic"))
    agg_searcher = aggregate_searcher(config_filepath)
    # Initialize search parameters
    _id = StringId("specific_id")
    _id_disabled = "disabled_id"
    ST = [:data, :metadata, :all]
    needles = [randstring(rand([1,2,3])) for _ in 1:5]
    #enable!(agg_searcher, _id_disabled)
    srcher = agg_searcher[_id]
    max_suggestions=10
    # Test that the whole thing does not crash
    for search_type in ST
        try
            search(agg_searcher,
                   needles,
                   search_type=search_type,
                   search_method=:exact,  # not used
                   max_suggestions=max_suggestions)
            @test true
        catch
            @test false
            rm(test_filepath, recursive=true, force=true)
        end
    end
    # Cleanup
    rm(test_filepath, recursive=true, force=true)
end
