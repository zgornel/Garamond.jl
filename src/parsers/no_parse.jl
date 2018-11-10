# Small function that returns 2 empty corpora that
# acts as a fake parser
function __parser_no_parse(args...)
    @warn "Using the default parser, no parsing done. Returning empty corpora."
    crps = Corpus(DEFAULT_DOC_TYPE(""))
    return crps, crps
end


