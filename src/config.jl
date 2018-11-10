########################################################
# Corpus Id's i.e. keys that uniquely identify corpora #
########################################################

struct HashId <: AbstractId
    id::UInt
end


struct StringId <: AbstractId
    id::String
end


show(io::IO, id::StringId) = print(io, "id=\"$(id.id)\"")
show(io::IO, id::HashId) = print(io, "id=0x$(string(id.id, base=16))")


random_id(::Type{HashId}) = HashId(hash(rand()))
random_id(::Type{StringId}) = StringId(randstring())


# Construct IDs
make_id(::Type{HashId}, id::String) = HashId(parse(UInt, id))  # the id has to be parsable to UInt
make_id(::Type{HashId}, id::T) where T<:Number = HashId(UInt(abs(id)))  # may fail for floats!
make_id(::Type{StringId}, id::T) where T<:AbstractString = StringId(String(id))
make_id(::Type{StringId}, id::T) where T<:Number = StringId(string(id))

const DEFAULT_ID_TYPE = StringId



################
# SearchConfig #
################
# SearchConfigs can be built from a data configuration file or manually
mutable struct SearchConfig{I<:AbstractId}
    # general
    id::I                           # searcher/corpus id
    search::Symbol                  # search type i.e. :classic, :semantic
    name::String                    # name of the searcher.corpus
    enabled::Bool                   # whether to use the corpus in search or not
    data_path::String               # file/directory path for the data (depends on what the parser accepts)
    parser::Function                # parser function used to obtain corpus
    # classic search
    count_type::Symbol              # search term counting type i.e. :tf, :tfidf etc (classic search)
    heuristic::Symbol               # search heuristic for recommendtations (classic search)
    # semantic search
    embeddings_path::String         # path to the embeddings file
    embeddings_type::Symbol         # type of the embeddings i.e. :conceptnet, :word2vec (semantic search)
    embedding_method::Symbol        # How to arrive at a single embedding from multiple i.e. :bow, :arora (semantic search)
    embedding_search_model::Symbol  # type of the search model i.e. :naive, :kdtree, :hnsw (semantic search)
    embedding_element_type::Symbol  # Type of the embedding elements
end


SearchConfig{I}() where I<:AbstractId =
    SearchConfig{I}(
        random_id(I), DEFAULT_SEARCH, "", false, "",
        get_parsing_function(DEFAULT_PARSER, false, "", ' '),
        DEFAULT_COUNT_TYPE, DEFAULT_HEURISTIC,
        "", DEFAULT_EMBEDDINGS_TYPE, DEFAULT_EMBEDDING_METHOD,
        DEFAULT_EMBEDDING_SEARCH_MODEL, DEFAULT_EMBEDDING_ELEMENT_TYPE)

# Keyword argument constructor; all arguments sho
SearchConfig(;
          id=random_id(DEFAULT_ID_TYPE),
          search=DEFAULT_SEARCH,
          name="",
          enabled=false,
          data_path="",
          parser=get_parsing_function(DEFAULT_PARSER, false, "", ' '),
          count_type=DEFAULT_COUNT_TYPE,
          heuristic=DEFAULT_HEURISTIC,
          embeddings_path="",
          embeddings_type=DEFAULT_EMBEDDINGS_TYPE,
          embedding_method=DEFAULT_EMBEDDING_METHOD,
          embedding_search_model=DEFAULT_EMBEDDING_SEARCH_MODEL,
          embedding_element_type=DEFAULT_EMBEDDING_ELEMENT_TYPE) =
    # Call normal constructor
    SearchConfig(id, search, name, enabled, data_path, parser,
                 count_type, heuristic,
                 embeddings_path, embeddings_type,
                 embedding_method, embedding_search_model,
                 embedding_element_type)


Base.show(io::IO, sconfig::SearchConfig) = begin
    printstyled(io, "SearchConfig for $(sconfig.name)\n")
    _status = ifelse(sconfig.enabled, "enabled", "disabled")
    _status_color = ifelse(sconfig.enabled, :light_green, :light_black)
    printstyled(io, "`-[$_status]", color=_status_color)
    _search_color = ifelse(sconfig.search==:classic, :cyan, :light_cyan)
    printstyled(io, "-[$(sconfig.search)] ", color=_search_color)
    printstyled(io, "$(sconfig.data_path)\n")
end



"""
    load_search_configs(filename)

Function that creates search configurations from a data configuration file
specified by `filename`. It returns a `Vector{SearchConfig}` that is used
to build the `Searcher` objects with wich search is performed.
"""
function load_search_configs(filename::AbstractString)
    # Read config (this should fail if config not found)
    dict_configs = JSON.parse(open(fid->read(fid, String), filename))
    n = length(dict_configs)
    # Create search configurations
    search_configs = [SearchConfig{DEFAULT_ID_TYPE}() for _ in 1:n]
    removable = Int[]  # search configs that have problems
    for (i, (sconfig, dconfig)) in enumerate(zip(search_configs, dict_configs))
        # Get search parameters accounting for missing values
        # by using default parameters where the case
        has_header = get(dconfig, "header", false)
        id = get(dconfig, "id", missing)
        if !ismissing(id)
            sconfig.id = make_id(DEFAULT_ID_TYPE, id)
        end
        globbing_pattern = get(dconfig, "globbing_pattern",
                               DEFAULT_GLOBBING_PATTERN)
        delimiter = get(dconfig, "delimiter", DEFAULT_DELIMITER)[1]  # take 1'st char
        sconfig.search = Symbol(get(dconfig, "search", DEFAULT_SEARCH))
        sconfig.name = get(dconfig, "name", "")
        sconfig.enabled = get(dconfig, "enabled", false)
        sconfig.data_path = get(dconfig, "data_path", "")
        sconfig.parser = get_parsing_function(Symbol(dconfig["parser"]),
                                              has_header,
                                              globbing_pattern,
                                              delimiter)
        sconfig.count_type = Symbol(get(dconfig, "count_type",
                                        DEFAULT_COUNT_TYPE))
        sconfig.heuristic = Symbol(get(dconfig, "heuristic",
                                       DEFAULT_HEURISTIC))
        sconfig.embeddings_path = get(dconfig, "embeddings_path", "")
        sconfig.embeddings_type = Symbol(get(dconfig, "embeddings_type",
                                             DEFAULT_EMBEDDINGS_TYPE))
        sconfig.embedding_method = Symbol(get(dconfig, "embedding_method",
                                              DEFAULT_EMBEDDING_METHOD))
        sconfig.embedding_search_model = Symbol(get(dconfig,
                                                "embedding_search_model",
                                                DEFAULT_EMBEDDING_SEARCH_MODEL))
        sconfig.embedding_element_type = Symbol(get(dconfig,
                                                "embedding_element_type",
                                                DEFAULT_EMBEDDING_SEARCH_MODEL))
        # Checks of the configuration parameter values; no checks
        # for the id (always works), name (always works),
        # enabled (must fail if wrong), parser (must fail if wrong),
        # globbing_pattern (must fail if wrong) and delimiter (should fail
        # for empty strings only)
        # search
        if !(sconfig.search in [:classic, :semantic])
            @warn "$(sconfig.id) Forcing search=$DEFAULT_SEARCH."
            sconfig.search = DEFAULT_SEARCH
        end
        # data path
        if !isfile(sconfig.data_path) && !isdir(sconfig.data_path)
            @show isfile(sconfig.data_path)
            @show isdir(sconfig.data_path)
            @warn "$(sconfig.id) Missing data, ignoring search configuration..."
            push!(removable, i)  # if there is no data file, cannot search
            continue
        end
        # Classic search specific options
        if sconfig.search == :classic
            # count type
            if !(sconfig.count_type in [:tf, :tfidf])
                @warn "$(sconfig.id) Forcing count_type=$DEFAULT_COUNT_TYPE."
                sconfig.count_type = DEFAULT_COUNT_TYPE
            end
            # heuristic
            if !(sconfig.heuristic in keys(HEURISTIC_TO_DISTANCE))
                @warn "$(sconfig.id) Forcing heuristic=$DEFAULT_HEURISTIC."
                sconfig.heuristic = DEFAULT_HEURISTIC
            end
        end
        # Semantic search specific options
        if sconfig.search == :semantic
            # word embeddings library path
            if !isfile(sconfig.embeddings_path)
                @warn "$(sconfig.id) Missing embeddings, ignoring search configuration..."
                push!(removable, i)  # if there is are no word embeddings, cannot search
                continue
            end
            # type of embeddings
            if !(sconfig.embeddings_type in [:word2vec, :conceptnet])
                @warn "$(sconfig.id) Forcing embeddings_type=$DEFAULT_EMBEDDINGS_TYPE."
                sconfig.embeddings_type = DEFAULT_EMBEDDINGS_TYPE
            end
            # embedding method
            if !(sconfig.embedding_method in [:bow, :arora])
                @warn "$(sconfig.id) Forcing embedding_method=$DEFAULT_EMBEDDING_METHOD."
                sconfig.embedding_method = DEFAULT_EMBEDDING_METHOD
            end
            # type of search model
            if !(sconfig.embedding_search_model in [:naive, :brutetree, :kdtree, :hnsw])
                @warn "$(sconfig.id) Forcing embedding_search_model=$DEFAULT_EMBEDDING_SEARCH_MODEL."
                sconfig.embedding_search_model = DEFAULT_EMBEDDING_SEARCH_MODEL
            end
            # type of the embedding elements
            if !(sconfig.embedding_element_type in [:Float32, :Float64])
                @warn "$(sconfig.id) Forcing embedding_element_type=$DEFAULT_EMBEDDING_ELEMENT_TYPE."
                sconfig.embedding_element_type = DEFAULT_EMBEDDING_ELEMENT_TYPE
            end
        end
    end
    # Remove search configs that have missing files
    deleteat!(search_configs, removable)
    return search_configs
end



"""
    get_parsing_config(parser, header, globbing_pattern, delimiter)

Function that generates a parsing function from a `parser` and
whether a `header` should be used. `globbing_pattern` and `delimiter`
are additional input parameters used by different parsers as outside
parameters.

Note: `parser` must be in the keys of the `PARSER_CONFIGS` constant. The name
      of the data parsing function is created as: `:__parser_<parser>` so,
      the function name `:__parser_delimited_format_1` corresponds to the
      parser `:delimited_format_1`.
"""
function get_parsing_function(parser::Symbol,
                              header::Bool,
                              globbing_pattern::String,
                              delimiter::Char) where T<:AbstractId
    PREFIX = :__parser_
    # Construct basic parsing function from parser name
    _function  = eval(Symbol(PREFIX, parser))
    # Get parser config
    _config = get(PARSER_CONFIGS,
                  parser,
                  Dict())
    # Build parsing function (a nice closure)
    function parsing_function(filename::String,
                              doc_type::Type{D}=DEFAULT_DOC_TYPE) where
            {T<:AbstractId, D<:AbstractDocument}
        return _function(filename,
                         _config,
                         doc_type,
                         delimiter=delimiter,
                         header=header,
                         globbing_pattern=globbing_pattern)
    end
    return parsing_function
end
