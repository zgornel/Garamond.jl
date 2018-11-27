####
# TODO(Corneliu): Make proper tests:
#   - test types (constructors)
#   - test basic functions (the important stuff)
#   - generate data and configs based on a set of single patameters
#     the ouput of data generation is used (where possible) in the configs
#   - test as exaustively as possible the search
####
using Test
using Random
using Garamond
using JSON



# Generates test files for delimited configurations
DELIMITER="|"
function generate_test_data(parser::Symbol)
    # Make directories
    tmp_path = tempdir()
    data_path = abspath(joinpath(tmp_path, "garamond", "test", "data"))
    mkpath(data_path)
    if parser == :delimited_format_1
        filename = joinpath(data_path, "file.tsv")
        nlines = rand([10, 30, 50])
        open(filename, "w") do fid
            for _ in 1:nlines
                line = join([randstring(rand(1:10)) for _ in 1:10], DELIMITER)*"\n"
                write(fid, line)
            end
        end
        return filename
    elseif parser == :directory_format_1
        directories = ["a","a/b","c"]
        for (i, dir) in enumerate(directories)
            file_path = joinpath(data_path, dir)
            mkpath(file_path)
            filename = joinpath(file_path, "file_$i.txt")
            open(filename, "w") do fid
                text = """this is text. this is another text. this text
                          provides some data for testing purposes.
                          the file name is $(filename) and this is all
                          information provided."""
                write(fid, text)
            end
        end
        return data_path
    else
        @error "Unknown config"
    end
    return filename
end



# Generate search configurations for directories
GLOBBING_PATTERN = "*"
function generate_test_configurations(data_path::String,
                                      parser::Symbol,
                                      search_approach::Symbol)
    # Classic search test configuration
    CLASSIC_CONFIGS = []
    _id = 1
    for _count_type in ["tf", "tfidf", "bm25"]
        for _heuristic in ["jaro", "levenshtein"]
            for _build_summary in [false, true]
                for _keep_data in [false, true]
                    dconfig = Dict("id"=> _id,
                                   "search" => search_approach,
                                   "data_path" => data_path,
                                   "parser" => parser,
                                   "enabled" => true,
                                   "header" => false,
                                   "delimiter" => DELIMITER,
                                   "show_progress" => false,
                                   "count_type" => _count_type,
                                   "heuristic" => _heuristic,
                                   "globbing_pattern" => GLOBBING_PATTERN,
                                   "build_summary" => _build_summary,
                                   "summary_ns" => 3,
                                   "keep_data" => _keep_data)
                    push!(CLASSIC_CONFIGS, dconfig)
                    _id+= 1
                end
            end
        end
    end
    # Semantic search test configuration
    SEMANTIC_CONFIGS = []
    dir = @__DIR__
    _id = 1
    for _embs_type in ["conceptnet", "word2vec"]
        for _emb_method in ["bow", "arora"]
            for _emb_model in ["naive", "brutetree", "kdtree", "hnsw"]
                for _emb_eltype in ["Float32","Float64"]
                    for _build_summary in [false, true]
                        for _keep_data in [false, true]
                            _embs_path = ifelse(_embs_type=="conceptnet",
                                    "$(@__DIR__)/embeddings/conceptnet/sample_model.txt",
                                    "$(@__DIR__)/embeddings/word2vec/sample_model.bin")
                            dconfig = Dict("id" => _id,
                                           "search"=> search_approach,
                                           "data_path" => data_path,
                                           "parser" => parser,
                                           "enabled" => true,
                                           "header" => false,
                                           "delimiter" => DELIMITER,
                                           "show_progress" => false,
                                           "embeddings_path" => _embs_path,
                                           "embeddings_type" => _embs_type,
                                           "embedding_method" => _emb_method,
                                           "embedding_search_model" => _emb_model,
                                           "embedding_element_type" => _emb_eltype,
                                           "globbing_pattern" => GLOBBING_PATTERN,
                                           "build_summary" => _build_summary,
                                           "summary_ns" => 3,
                                           "keep_data"=>_keep_data)
                            push!(SEMANTIC_CONFIGS, dconfig)
                            _id+= 1
                        end
                    end
                end
            end
        end
    end
    # Write configs to file
    tmp_path = tempdir()
    config_path = abspath(joinpath(tmp_path, "garamond", "test", "configs"))
    mkpath(config_path)
    if search_approach == :classic
        config = CLASSIC_CONFIGS
    else
        config = SEMANTIC_CONFIGS
    end
    config_filename = joinpath(config_path, ".config.json")
    open(config_filename, "w") do fid
        write(fid, JSON.json(config))
    end
    return config_filename
end



# Test search
@testset "SEARCH" begin
    # Generate test files
    parsers = [:delimited_format_1, :directory_format_1]
    # Loop over parsers and search types
    for parser in parsers
        for search_approach in [:classic, :semantic]
            data_path = generate_test_data(parser)
            config_path = generate_test_configurations(
                            data_path, parser, search_approach)
            # Create a distinct testset for each type of search
            # i.e. classic, semantic and each parser
            @testset "$search_approach, $parser" begin
                # Create corpora searches
                srchers = load_searchers(config_path)
                # Initialize search parameters
                ST = [:data, :metadata, :all]
                SM = [:exact, :regex]
                MAX_SUGGESTIONS=[0, 5]
                needles = [randstring(rand([1,2,3])) for _ in 1:3]
                # Test that the whole thing does not crash
                for search_type in ST
                    for search_method in SM
                        for max_suggestions in MAX_SUGGESTIONS
                            #try
                                search(srchers,
                                       needles,
                                       search_type=search_type,
                                       search_method=search_method,
                                       max_corpus_suggestions=max_suggestions)
                                @test true
                            #catch
                            #    @test false
                            #    rm(data_path, recursive=true, force=true)
                            #    rm(config_path, recursive=true, force=true)
                            #end
                        end
                    end
                end
                # Cleanup
                rm(data_path, recursive=true, force=true)
                rm(config_path, recursive=true, force=true)
            end
        end
    end
end
