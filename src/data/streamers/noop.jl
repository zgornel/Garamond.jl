# The indentity function
function noop_streamer(rawdata)
    @warn "Noop data streamer, returning nothing."
    return nothing
end
