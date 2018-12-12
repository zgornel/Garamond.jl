using Documenter, Garamond

# Make src directory available
push!(LOAD_PATH,"../src/")

# Make documentation
makedocs(
    modules = [Garamond],
    format = :html,
    sitename = "Garamond.jl",
    authors = "Corneliu Cofaru, 0x0α Research",
    clean = true,
    debug = true,
    pages = [
        "Introduction" => "index.md",
        "Configuration" => "configuration.md",
        "Client/Server" => "clientserver.md",
        "Notes" => "notes.md",
        "Feature list" => "features.md",
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
