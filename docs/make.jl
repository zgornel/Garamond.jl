using Documenter, Garamond

# Make src directory available
push!(LOAD_PATH,"../src/")

# Make documentation
makedocs(
    modules = [Garamond],
    format = :html,
    pages = [
        "Home" => "index.md",
        "Manual" => "pages/manual.md",
        "API" => "pages/api.md",
    ],
    sitename = "Garamond.jl",
    authors = "Corneliu Cofaru, 0x0α Research",
)

# Deploy documentation
deploydocs(
    repo = "github.com/zgornel/Garamond.jl.git",
    julia = "1.0",
    target = "build",
    deps = nothing,
    make = nothing,
)
