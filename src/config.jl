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
make_id(::Type{HashId}, id::T) where T<:Integer = HashId(UInt(abs(id)))
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
end


# Small function that returns 2 empty corpora
fake_parser(args...) = begin
    crps = Corpus(DEFAULT_DOC_TYPE(""))
    return crps, crps
end

SearchConfig{I}() where I<:AbstractId =
    SearchConfig{I}(
        random_id(I), DEFAULT_SEARCH, "", false, "",
        fake_parser, DEFAULT_COUNT_TYPE, DEFAULT_HEURISTIC,
        "", DEFAULT_EMBEDDINGS_TYPE, DEFAULT_EMBEDDING_METHOD,
        DEFAULT_EMBEDDING_SEARCH_MODEL)

# Keyword argument constructor; all arguments sho
SearchConfig(;
          id=random_id(DEFAULT_ID_TYPE),
          search=DEFAULT_SEARCH,
          name="",
          enabled=false,
          data_path="",
          parser=fake_parser,
          count_type=DEFAULT_COUNT_TYPE,
          heuristic=DEFAULT_HEURISTIC,
          embeddings_path="",
          embeddings_type=DEFAULT_EMBEDDINGS_TYPE,
          embedding_method=DEFAULT_EMBEDDING_METHOD,
          embedding_search_model=DEFAULT_EMBEDDING_SEARCH_MODEL) =
    # Call normal constructor
    SearchConfig(id, search, name, enabled, data_path, parser,
                 count_type, heuristic,
                 embeddings_path, embeddings_type,
                 embedding_method, embedding_search_model)


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
        has_header = dconfig["header"]
        sconfig.id = make_id(DEFAULT_ID_TYPE, dconfig["id"])
        sconfig.search = Symbol(get(dconfig, "search", DEFAULT_SEARCH))
        sconfig.name = dconfig["name"]
        sconfig.enabled = dconfig["enabled"]
        sconfig.data_path = dconfig["data_path"]
        sconfig.parser = get_parsing_function(Symbol(dconfig["parser"]),
                                              has_header)
        sconfig.count_type = Symbol(get(dconfig, "count_type", 
                                        DEFAULT_COUNT_TYPE))
        sconfig.heuristic = Symbol(get(dconfig, "heuristic",
                                       DEFAULT_HEURISTIC))
        sconfig.embeddings_path = dconfig["embeddings_path"]
        sconfig.embeddings_type = Symbol(get(dconfig, "embeddings_type",
                                             DEFAULT_EMBEDDINGS_TYPE))
        sconfig.embedding_method = Symbol(get(dconfig, "embedding_method",
                                              DEFAULT_EMBEDDING_METHOD))
        sconfig.embedding_search_model = Symbol(get(dconfig,
                                                "embedding_search_model",
                                                DEFAULT_EMBEDDING_SEARCH_MODEL))
        # Checks of the configuration parameter values; no checks 
        # for the id (always works), name (has to be present),
        # enabled (must fail if wrong) and parser (must fail if wrong)
        # search
        if !(sconfig.search in [:classic, :semantic])
            @warn "id=$(sconfig.id) Forcing search=$DEFAULT_SEARCH."
            sconfig.search = DEFAULT_SEARCH
        end
        # data path
        if !isfile(sconfig.data_path) && !ispath(sconfig.data_path)
            @warn "id=$(sconfig.id) Missing data, ignoring search configuration..."
            push!(removable, i)  # if there is no data file, cannot search
            continue
        end
        # Classic search specific options
        if sconfig.search == :classic
            # count type
            if !(sconfig.count_type in [:tf, :tfidf])
                @warn "id=$(sconfig.id) Forcing count_type=$DEFAULT_COUNT_TYPE."
                sconfig.count_type = DEFAULT_COUNT_TYPE
            end
            # heuristic
            if !(sconfig.heuristic in keys(HEURISTIC_TO_DISTANCE))
                @warn "id=$(sconfig.id) Forcing heuristic=$DEFAULT_HEURISTIC."
                sconfig.heuristic = DEFAULT_HEURISTIC
            end
        end
        # Semantic search specific options
        if sconfig.search == :semantic
            # word embeddings library path
            if !isfile(sconfig.embeddings_path)
                @warn "id=$(sconfig.id) Missing embeddings, ignoring search configuration..."
                push!(removable, i)  # if there is are no word embeddings, cannot search
                continue
            end
            # type of embeddings
            if !(sconfig.embeddings_type in [:word2vec, :conceptnet])
                @warn "id=$(sconfig.id) Forcing embeddings_type=$DEFAULT_EMBEDDINGS_TYPE."
                sconfig.embeddings_type = DEFAULT_EMBEDDINGS_TYPE
            end
            # embedding method
            if !(sconfig.embedding_method in [:bow, :arora])
                @warn "id=$(sconfig.id) Forcing embedding_method=$DEFAULT_EMBEDDING_METHOD."
                sconfig.embedding_method = DEFAULT_EMBEDDING_METHOD
            end
            # type of search model
            if !(sconfig.embedding_search_model in [:naive, :brutetree, :kdtree, :hnsw])
                @warn "id=$(sconfig.id) Forcing embedding_search_model=$DEFAULT_EMBEDDING_SEARCH_MODEL."
                sconfig.embedding_search_model = DEFAULT_EMBEDDING_SEARCH_MODEL
            end
        end
    end
    # Remove search configs that have missing files
    deleteat!(search_configs, removable)
    return search_configs
end



""" 
    get_parsing_config(name, header)

Function that generates a parsing function from a parser `name` and 
whether a `header` should be used.
Note: `name` must be in the keys of the `PARSER_CONFIGS` constant. The name
      of the data parsing function is created as: `:__parser_<name>` so,
      the name `:__parser_csv_format_1` corresponds to the name `:csv_format_1`
"""
function get_parsing_function(name::Symbol,
                              header::Bool=false) where T<:AbstractId
    PREFIX = :__parser_
    # Construct basic parsing function from parser option value ie. __parser_<option> function
    _function  = eval(Symbol(PREFIX, name))
    # Get parser config
    _config = get(PARSER_CONFIGS, name, nothing)
    _config isa Nothing && @error ":$config_name parser configuration not found!"
    # Build parsing function (a nice closure)
    function parsing_function(filename::String,
                              doc_type::Type{D}=DEFAULT_DOC_TYPE) where
            {T<:AbstractId, D<:AbstractDocument}
        return _function(filename,
                         _config,
                         doc_type,
                         delim='|',
                         header=header)
    end
    return parsing_function
end
