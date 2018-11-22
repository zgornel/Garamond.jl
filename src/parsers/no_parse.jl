# Parser equivalent to parsing nothing
function __parser_no_parse(args...)
    @warn "Using the default parser, no parsing done. Returning empty structures."
    return Vector{String}[], DocumentMetadata[]
end


