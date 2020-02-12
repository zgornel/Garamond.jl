module GaramondTesting

using Test
using Random
using JuliaDB
using EmbeddingsAnalysis
using Garamond
#using JSON

# TODO(Corneliu): Complete testing framework redo
include("data/datagenerator.jl")
include("config/config_generator.jl")
include("input_parsers.jl")
include("db.jl")

end
