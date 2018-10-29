#############
# SearchConfig #
#############
# SearchConfigs can be built from a data configuration file or manually
mutable struct SearchConfig{T<:AbstractId}
    path::String        # file/directory path (depends on what the parser accepts)
    name::String        # name of corpus
    id::T
    parser::Function    # file/directory parser function used to obtain corpus
    termimp::Symbol     # term importance type i.e. :tf, :tfidf etc
    heuristic::Symbol   # search heuristic for recommendtations
    enabled::Bool       # whether to use the corpus in search or not
end


# Small function that returns 2 empty corpora
_fake_parser(args...) = begin
    crps = Corpus(DEFAULT_DOC_TYPE(""))
    return crps, crps
end


SearchConfig(;path="",
          name="",
          id=random_id(DEFAULT_ID_TYPE),
          parser=_fake_parser,
          termimp=DEFAULT_TERM_IMPORTANCE,
          heuristic=DEFAULT_HEURISTIC,
          enabled=false) =
    SearchConfig(path, name, id, parser, termimp, heuristic, enabled)


Base.show(io::IO, cref::SearchConfig) = begin
    printstyled(io, "$(typeof(cref)) for $(cref.name)\n")
    _status = ifelse(cref.enabled, "Enabled", "Disabled")
    _status_color = ifelse(cref.enabled, :light_green, :light_black)
    printstyled(io, "`-[$_status] ", color=_status_color)
    printstyled(io, "$(cref.path)\n")
end

