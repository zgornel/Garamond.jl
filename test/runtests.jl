using Test
using Random
using Garamond
using JSON



# Generates test files in temporary directory
function generate_test_files(parser_config::Symbol, sep::String="|")
    # Make directories
    tmp_path = tempdir()
    data_filepath = abspath(joinpath(tmp_path, "garamond", "test"))
    mkpath(data_filepath)
    # Test for parser configuration option
    if parser_config == :csv_config_1
        nlines = rand([100, 300, 500], 3)  # 3 files, hard fixed by config
        for i in 1:length(nlines)
            filename = joinpath(data_filepath, "test_file_$(i)_csv_format_1.tsv")
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
    return data_filepath
end



# Generate search configurations
function generate_test_configurations(config_type::Symbol)
    # Classic search test configuration
    CLASSIC_CONFIG = [
        Dict("id"=> "specific_id",
             "search" => "classic",
             "data_path" => joinpath(tempdir(),"garamond",
                                    "test","test_file_1_csv_format_1.tsv"),
             "parser" => "csv_format_1",
             "enabled" => true,
             "header" => false,
             "count_type" => "tfidf",
             "heuristic" =>"jaro"),
        Dict(# random id
             "search" => "classic",
             "data_path" => joinpath(tempdir(),"garamond",
                                    "test","test_file_1_csv_format_1.tsv"),
             "parser" => "csv_format_1",
             "enabled" => true,
             "header" => false,
             "count_type" => "tf",
             "heuristic" =>"levenshtein"),
        Dict("id"=> "disabled_id",
             "search" => "classic",
             "data_path" => joinpath(tempdir(),"garamond",
                                    "test","test_file_1_csv_format_1.tsv"),
             "parser" => "csv_format_1",
             "enabled" => false,
             "header" => false,
             "count_type" => "tfidf",
             "heuristic" =>"jaro")
       ]
    # Semantic search test configuration
    SEMANTIC_CONFIG = []
    dir = @__DIR__
    _id = 1
    for _embs_type in ["conceptnet", "word2vec"]
        for _emb_method in ["bow", "arora"]
            for _emb_model in ["naive", "brutetree", "kdtree", "hnsw"]
                _embs_path = ifelse(_embs_type=="conceptnet",
                        "$(@__DIR__)/embeddings/conceptnet/sample_model.txt",
                        "$(@__DIR__)/embeddings/word2vec/sample_model.bin")
                dconfig = Dict("id" => _id,
                               "search"=> "semantic",
                               "data_path" => joinpath(tempdir(),"garamond",
                                   "test","test_file_1_csv_format_1.tsv"),
                               "parser" => "csv_format_1",
                               "enabled" => true,
                               "header" => false,
                               "embeddings_path" => _embs_path,
                               "embeddings_type" => _embs_type,
                               "embedding_method" => _emb_method,
                               "embedding_search_model" => _emb_model)
                push!(SEMANTIC_CONFIG, dconfig)
                _id+= 1
            end
        end
    end
    # Write configs to file
    tmp_path = tempdir()
    config_filepath = abspath(joinpath(tmp_path, "garamond", "test", "configs"))
    mkpath(config_filepath)
    if config_type == :classic
        config = CLASSIC_CONFIG
    else
        config = SEMANTIC_CONFIG
    end
    config_filename = joinpath(config_filepath, ".config.json")
    open(config_filename, "w") do fid
        write(fid, JSON.json(config))
    end
    return config_filename
end



@testset "Classic search test... (csv_format_1)" begin
    # Generate test files
    data_filepath = generate_test_files(:csv_config_1)
    config_filepath = generate_test_configurations(:classic)
    # Create corpora searches
    srchers = load_searchers(config_filepath)
    # Initialize search parameters
    ST = [:data, :metadata, :all]
    SM = [:exact, :regex]
    needles = [randstring(rand([1,2,3])) for _ in 1:5]
    MAX_SUGGESTIONS=[0, 5]
    # Test that the whole thing does not crash
    for search_type in ST
        for search_method in SM
            for max_suggestions in MAX_SUGGESTIONS
                try
                    search(srchers,
                           needles,
                           search_type=search_type,
                           search_method=search_method,
                           max_corpus_suggestions=max_suggestions)
                    @test true
                catch
                    @test false
                    rm(data_filepath, recursive=true, force=true)
                    rm(config_filepath, recursive=true, force=true)
                end
            end
        end
    end
    # Cleanup
    rm(data_filepath, recursive=true, force=true)
    rm(config_filepath, recursive=true, force=true)
end



@testset "Semantic search test... (csv_format_1)" begin
    # Generate test files
    data_filepath = generate_test_files(:csv_config_1)
    config_filepath = generate_test_configurations(:semantic)
    # Create corpora searches
    srchers = load_searchers(config_filepath)
    # Initialize search parameters
    ST = [:data, :metadata, :all]
    needles = [randstring(rand([1,2,3])) for _ in 1:5]
    max_suggestions=10
    # Test that the whole thing does not crash
    for search_type in ST
        try
            search(srchers,
                   needles,
                   search_type=search_type,
                   search_method=:exact,  # not used
                   max_corpus_suggestions=max_suggestions)
            @test true
        catch
            @test false
            rm(data_filepath, recursive=true, force=true)
            rm(config_filepath, recursive=true, force=true)
        end
    end
    # Cleanup
    rm(data_filepath, recursive=true, force=true)
    rm(config_filepath, recursive=true, force=true)
end
