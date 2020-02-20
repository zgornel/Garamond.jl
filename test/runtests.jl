module GaramondTesting

using Test
using Random
using SparseArrays
using JuliaDB
using EmbeddingsAnalysis
using Garamond
#using JSON

# TODO(Corneliu): Add more tests
include("data/datagenerator.jl")
include("configs/configgenerator.jl")
include("input_parsers.jl")
include("db.jl")
include("index.jl")
include("indexfilter.jl")

end
