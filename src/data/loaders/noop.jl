function noop_loader(args...; kwargs...)
    @warn "Noop data loader, exiting gracefully..."
    exit()
end
