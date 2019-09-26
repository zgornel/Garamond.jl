# Snippet that includes all files located in the current directory
__loaders_path = joinpath(@__DIR__, "loaders")
if isdir(__loaders_path)
    for content in readdir(__loaders_path)
        try
            contentpath = joinpath(__loaders_path, content)
            if isfile(contentpath) && endswith(contentpath, ".jl")
                @info "• data loaders, including: $content..."
                include(contentpath)
            end
        catch e
            @warn "Could not include $contentpath..."
        end
    end
end
