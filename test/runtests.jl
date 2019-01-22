module GaramondTesting

using Test
using Random
using Garamond
using JSON

# Generate test data and
# searcher configs
include("datagen.jl")
# Test search
include("search.jl")

end
