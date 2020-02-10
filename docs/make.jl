using Pkg
Pkg.add("Documenter")
using Documenter, Garamond

# Make src directory available
push!(LOAD_PATH,"../src/")

# Make documentation
makedocs(
    modules = [Garamond],
    format = Documenter.HTML(),
    sitename = " ",
    authors = "Corneliu Cofaru, 0x0α Research",
    clean = true,
    debug = true,
    pages = [
        "Introduction" => "index.md",
        "Getting started" => "getting_started.md",
        "Configuration" => "configuration.md",
        "Client/Server" => "clientserver.md",
        "Building" => "build.md",
        "Remarks" => "remarks.md",
        "API Reference" => "api.md",
    ]
)

# Deploy documentation
deploydocs(
    repo = "github.com/zgornel/Garamond.jl.git",
    target = "build",
    deps = nothing,
    make = nothing
)
