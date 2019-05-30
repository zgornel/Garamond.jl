# Generates test files for delimited configurations
DELIMITER="|"
PARSER_CONFIGS = Dict(
   :delimited_format_1 =>
       Dict("metadata"=> Dict(1=>"id",
                              2=>"author",
                              3=>"name",
                              4=>"publisher",
                              5=>"edition_year",
                              6=>"published_year",
                              7=>"language",
                              8=>"note",
                              9=>"location"),
            "data"=> [2, 3, 8]
           ),
    :directory_format_1 => nothing)


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
                text = """This is text. This is another text. This text
                          provides some data for testing purposes.
                          The file name is $(filename) and this text
                          is all information provided. Nothing more should
                          be needed."""
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
function generate_test_confs(data_path::String, parser::Symbol)
    # Semantic search test configuration
    dir = @__DIR__
    id = 1
    # Create configs directory
    tmp_path = tempdir()
    config_path = abspath(joinpath(tmp_path, "garamond", "test", "configs"))
    mkpath(config_path)
    # Generate data configuration files
    for vectors in ["bm25", "conceptnet", "word2vec", "glove"]  # "count", "tf", "tfidf" ommitted
        for vectors_transform in ["none", "rp", "lsa"]
            for search_index in ["naive", "brutetree", "kdtree", "hnsw"]
                for doc2vec_method in ["boe", "sif" , "borep", "cpmean", "disc"]
                for heuristic in [nothing, "levenshtein"]
                for vectors_eltype in ["Float32"]
                for build_summary in [false, true]
                for keep_data in [false, true]
                    local embeddings_path, embeddings_kind
                    if vectors == "conceptnet"
                        embeddings_path = "$(@__DIR__)/embeddings/conceptnet/sample_model.txt"
                        embeddings_kind = "text"  #not used
                    elseif vectors == "word2vec"
                        embeddings_path = "$(@__DIR__)/embeddings/word2vec/sample_model.bin"
                        embeddings_kind = "binary"
                    elseif vectors == "glove"
                        embeddings_path = "$(@__DIR__)/embeddings/glove/sample_model.txt"
                        embeddings_kind = "text"
                    else
                        embeddings_path = nothing
                        embeddings_kind = "not_important"
                    end
                    # Data config structure
                    dconfig = Dict("id" => id,
                                   "description" => "Sample description",
                                   "enabled" => true,
                                   "data_path" => data_path,
                                   "parser" => parser,
                                   "parser_config" => PARSER_CONFIGS[parser],
                                   "header" => false,
                                   "delimiter" => DELIMITER,
                                   "globbing_pattern" => GLOBBING_PATTERN,
                                   "show_progress" => false,
                                   "keep_data"=>keep_data,
                                   "build_summary" => build_summary,
                                   "summary_ns" => 3,
                                   "vectors" => vectors,
                                   "vectors_transform" => vectors_transform,
                                   "vectors_dimension" => 1,
                                   "vectors_eltype" => vectors_eltype,
                                   "embeddings_kind" => embeddings_kind,
                                   "doc2vec_method" => doc2vec_method,
                                   "search_index" => search_index)
                    # Add non-nothing values options
                    heuristic != nothing && push!(dconfig, "heuristic" => heuristic)
                    embeddings_path != nothing && push!(dconfig, "embeddings_path"=>embeddings_path)
                    # Write config to file
                    filename = joinpath(config_path, ".config_$(id).json")
                    open(filename, "w") do fid
                        write(fid, JSON.json([dconfig]))  # write 1-element array of Dict
                    end
                    id += 1
                end
        end end end
        end end
    end end
    # Write configs to file
    return config_path
end
