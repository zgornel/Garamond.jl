module GaramondTesting

using Test
using Logging
using Random
using SparseArrays
using JuliaDB
using EmbeddingsAnalysis
using Garamond
#using JSON

# TODO(Corneliu): Add more tests
test_logger = ConsoleLogger(stdout, Logging.Error)  # supresses warnings, infos
with_logger(test_logger) do
    # Necessary data/config generators
    include("data/datagenerator.jl")
    include("configs/configgenerator.jl")
    # Tests
    include("input_parsers.jl")
    include("db.jl")
    include("index.jl")
    include("embedder.jl")
    include("env.jl")
    include("indexfilter.jl")
    include("config_parser.jl")
end

end
