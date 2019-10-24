function noop_loader(args...; kwargs...)
    @info "Noop data loader: exiting gracefully (nothing to do)..."
    exit()
end
