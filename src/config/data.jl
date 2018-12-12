########################################################
# Corpus Id's i.e. keys that uniquely identify corpora #
########################################################
struct StringId
    id::String
end

# Utils
show(io::IO, id::StringId) = print(io, "id=\"$(id.id)\"")
random_id(::Type{StringId}) = StringId(randstring())

# Construct IDs
make_id(::Type{StringId}, id::T) where T<:AbstractString = StringId(String(id))
make_id(::Type{StringId}, id::T) where T<:Number = StringId(string(id))



################
# SearchConfig #
################
# SearchConfigs can be built from a data configuration file or manually
mutable struct SearchConfig
    # general
    id::StringId                    # searcher/corpus id
    search::Symbol                  # search type i.e. :classic, :semantic
    description::String             # description of the searcher.corpus
    enabled::Bool                   # whether to use the corpus in search or not
    data_path::String               # file/directory path for the data (depends on what the parser accepts)
    parser::Function                # parser function used to obtain corpus
    parser_config::Union{Nothing,Dict}  # parser configuration
    build_summary::Bool             # whether to summarize or not the documents
    summary_ns::Int                 # the number of sentences in the summary
    keep_data::Bool                 # whether to keep document data, metadata
    stem_words::Bool                # whether to stem data or not
    # classic search
    count_type::Symbol              # search term counting type i.e. :tf, :tfidf etc (classic search)
    heuristic::Symbol               # search heuristic for recommendtations (classic search)
    # semantic search
    embeddings_path::String         # path to the embeddings file
    embeddings_library::Symbol      # embeddings library i.e. :conceptnet, :word2vec, :glove (semantic search)
    embeddings_kind::Symbol         # Type of the embedding file for Word2Vec, GloVe i.e. :text, :binary
    embedding_method::Symbol        # How to arrive at a single embedding from multiple i.e. :bow, :arora (semantic search)
    embedding_search_model::Symbol  # type of the search model i.e. :naive, :kdtree, :hnsw (semantic search)
    embedding_element_type::Symbol  # Type of the embedding elements
    glove_vocabulary::Union{Nothing, String}  # Path to a GloVe-generated vocabulary file (only for binary embeddings)
    # test stripping flags
    text_strip_flags::UInt32        # How to strip text data before indexing
    metadata_strip_flags::UInt32    # How to strip text metadata before indexing
    query_strip_flags::UInt32       # How to strip queries before searching
    summarization_strip_flags::UInt32 # How to strip text before summarization
end

# Keyword argument constructor; all arguments sho
SearchConfig(;
          id=random_id(StringId),
          search=DEFAULT_SEARCH,
          description="",
          enabled=false,
          data_path="",
          parser=get_parsing_function(DEFAULT_PARSER,
                                      DEFAULT_PARSER_CONFIG,
                                      false,
                                      DEFAULT_DELIMITER,
                                      DEFAULT_GLOBBING_PATTERN,
                                      DEFAULT_BUILD_SUMMARY,
                                      DEFAULT_SUMMARY_NS,
                                      DEFAULT_SUMMARIZATION_STRIP_FLAGS,
                                      DEFAULT_SHOW_PROGRESS),
          parser_config=DEFAULT_PARSER_CONFIG,
          build_summary=DEFAULT_BUILD_SUMMARY,
          summary_ns=DEFAULT_SUMMARY_NS,
          keep_data=DEFAULT_KEEP_DATA,
          stem_words=DEFAULT_STEM_WORDS,
          count_type=DEFAULT_COUNT_TYPE,
          heuristic=DEFAULT_HEURISTIC,
          embeddings_path="",
          embeddings_library=DEFAULT_EMBEDDINGS_LIBRARY,
          embeddings_kind=DEFAULT_EMBEDDINGS_KIND,
          embedding_method=DEFAULT_EMBEDDING_METHOD,
          embedding_search_model=DEFAULT_EMBEDDING_SEARCH_MODEL,
          embedding_element_type=DEFAULT_EMBEDDING_ELEMENT_TYPE,
          glove_vocabulary=nothing,
          text_strip_flags=DEFAULT_TEXT_STRIP_FLAGS,
          metadata_strip_flags=DEFAULT_METADATA_STRIP_FLAGS,
          query_strip_flags=DEFAULT_QUERY_STRIP_FLAGS,
          summarization_strip_flags=DEFAULT_SUMMARIZATION_STRIP_FLAGS) =
    # Call normal constructor
    SearchConfig(id, search, description, enabled, data_path,
                 parser, parser_config,
                 build_summary, summary_ns, keep_data, stem_words,
                 count_type, heuristic,
                 embeddings_path, embeddings_library, embeddings_kind,
                 embedding_method, embedding_search_model,
                 embedding_element_type,
                 glove_vocabulary,
                 text_strip_flags, metadata_strip_flags,
                 query_strip_flags, summarization_strip_flags)


Base.show(io::IO, sconfig::SearchConfig) = begin
    printstyled(io, "SearchConfig for $(sconfig.id)\n")
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
to build the `Searcher` objects with which search is performed.
"""
function load_search_configs(filename::AbstractString)
    # Read config (this should fail if config not found)
    dict_configs = JSON.parse(open(fid->read(fid, String), filename))
    n = length(dict_configs)
    # Create search configurations
    search_configs = [SearchConfig() for _ in 1:n]
    removable = Int[]  # search configs that have problems
    must_have_keys = ["search", "data_path", "parser"]
    for (i, (sconfig, dconfig)) in enumerate(zip(search_configs, dict_configs))
        if !all(map(key->haskey(dconfig, key), must_have_keys))
            @warn "$(sconfig.id) Missing options from [$must_have_keys]. Ignoring search configuration..."
            push!(removable, i)  # if there is are no word embeddings, cannot search
            continue
        end
        # Get search parameters accounting for missing values
        # by using default parameters where the case
        header = get(dconfig, "header", false)
        sconfig.id = make_id(StringId, get(dconfig, "id", randstring(10)))
        globbing_pattern = get(dconfig, "globbing_pattern", DEFAULT_GLOBBING_PATTERN)
        show_progress = get(dconfig, "show_progress", DEFAULT_SHOW_PROGRESS)
        delimiter = get(dconfig, "delimiter", DEFAULT_DELIMITER)
        sconfig.search = Symbol(get(dconfig, "search", DEFAULT_SEARCH))
        sconfig.description = get(dconfig, "description", "")
        sconfig.enabled = get(dconfig, "enabled", false)
        sconfig.data_path = get(dconfig, "data_path", "")
        sconfig.build_summary = get(dconfig, "build_summary", DEFAULT_BUILD_SUMMARY)
        sconfig.summary_ns = get(dconfig, "summary_ns", DEFAULT_SUMMARY_NS)
        sconfig.keep_data = get(dconfig, "keep_data", DEFAULT_KEEP_DATA)
        sconfig.stem_words = get(dconfig, "stem_words", DEFAULT_STEM_WORDS)
        sconfig.count_type = Symbol(get(dconfig, "count_type", DEFAULT_COUNT_TYPE))
        sconfig.heuristic = Symbol(get(dconfig, "heuristic", DEFAULT_HEURISTIC))
        sconfig.embeddings_path = get(dconfig, "embeddings_path", "")
        sconfig.embeddings_library = Symbol(get(dconfig, "embeddings_library",
                                                DEFAULT_EMBEDDINGS_LIBRARY))
        sconfig.embeddings_kind = Symbol(get(dconfig, "embeddings_kind",
                                             DEFAULT_EMBEDDINGS_KIND))
        sconfig.embedding_method = Symbol(get(dconfig, "embedding_method",
                                              DEFAULT_EMBEDDING_METHOD))
        sconfig.embedding_search_model = Symbol(get(dconfig, "embedding_search_model",
                                                    DEFAULT_EMBEDDING_SEARCH_MODEL))
        sconfig.embedding_element_type = Symbol(get(dconfig, "embedding_element_type",
                                                    DEFAULT_EMBEDDING_ELEMENT_TYPE))
        sconfig.glove_vocabulary= get(dconfig, "glove_vocabulary", nothing)
        sconfig.text_strip_flags = UInt32(get(dconfig, "text_strip_flags",
                                              DEFAULT_TEXT_STRIP_FLAGS))
        sconfig.metadata_strip_flags = UInt32(get(dconfig, "metadata_strip_flags",
                                                  DEFAULT_METADATA_STRIP_FLAGS))
        sconfig.query_strip_flags = UInt32(get(dconfig, "query_strip_flags",
                                               DEFAULT_QUERY_STRIP_FLAGS))
        sconfig.summarization_strip_flags = UInt32(get(dconfig,
                                                       "summarization_strip_flags",
                                                        DEFAULT_SUMMARIZATION_STRIP_FLAGS))
        # Construct parser (built last as requires other parameters)
        sconfig.parser_config = get(dconfig, "parser_config", DEFAULT_PARSER_CONFIG)
        sconfig.parser = get_parsing_function(Symbol(dconfig["parser"]),
                                              sconfig.parser_config,
                                              header,
                                              delimiter,
                                              globbing_pattern,
                                              sconfig.build_summary,
                                              sconfig.summary_ns,
                                              sconfig.summarization_strip_flags,
                                              show_progress)
        # Checks of the configuration parameter values;
        # No checks performed for:
        # - id (always works)
        # - description (always works)
        # - enabled (must fail if wrong)
        # - parser (must fail if wrong)
        # - parser_config (must fail if wrong)
        # - globbing_pattern (must fail if wrong)
        # - build_summary (should fail if wrong)
        # - text data/metadata/query/summarization flags (must fail if wrong)
        ###
        # search
        if !(sconfig.search in [:classic, :semantic])
            @warn "$(sconfig.id) Defaulting search=$DEFAULT_SEARCH."
            sconfig.search = DEFAULT_SEARCH
        end
        # data path
        if !isfile(sconfig.data_path) && !isdir(sconfig.data_path)
            @warn "$(sconfig.id) Missing data, ignoring search configuration..."
            push!(removable, i)  # if there is no data file, cannot search
            continue
        end
        # summary_ns i.e. the number of sentences in a summary
        if !(typeof(sconfig.summary_ns) <: Integer) || sconfig.summary_ns <= 0
            @warn "$(sconfig.id) Defaulting summary_ns=$DEFAULT_SUMMARY_NS."
            sconfig.summary_ns = DEFAULT_SUMMARY_NS
        end
        # keep_data
        if !(typeof(sconfig.keep_data) <: Bool)
            @warn "$(sconfig.keep_data) Defaulting keep_data=$DEFAULT_KEEP_DATA."
            sconfig.keep_data = DEFAULT_KEEP_DATA
        end
        # stem_words
        if !(typeof(sconfig.stem_words) <: Bool)
            @warn "$(sconfig.stem_words) Defaulting stem_words=$DEFAULT_STEM_WORDS."
            sconfig.stem_words = DEFAULT_STEM_WORDS
        end
        # delimiter
        if !(typeof(delimiter) <: AbstractString) || length(delimiter) == 0
            @warn "$(sconfig.id) Defaulting delimiter=$DEFAULT_DELIMITER."
            sconfig.delimiter = DEFAULT_DELIMITER
        end
        # Classic search specific options
        if sconfig.search == :classic
            # count type
            if !(sconfig.count_type in [:tf, :tfidf, :bm25])
                @warn "$(sconfig.id) Defaulting count_type=$DEFAULT_COUNT_TYPE."
                sconfig.count_type = DEFAULT_COUNT_TYPE
            end
            # heuristic
            if !(sconfig.heuristic in keys(HEURISTIC_TO_DISTANCE))
                @warn "$(sconfig.id) Defaulting heuristic=$DEFAULT_HEURISTIC."
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
            if !(sconfig.embeddings_library in [:conceptnet, :word2vec, :glove])
                @warn "$(sconfig.id) Defaulting embeddings_library=$DEFAULT_EMBEDDINGS_LIBRARY."
                sconfig.embeddings_library = DEFAULT_EMBEDDINGS_LIBRARY
            end
            # embeddings kind
            if !(sconfig.embeddings_kind in [:binary, :text])
                @warn "$(sconfig.id) Defaulting embeddings_kind=$DEFAULT_EMBEDDINGS_KIND."
                sconfig.embeddings_kind = DEFAULT_EMBEDDINGS_KIND
            end
            # embedding method
            if !(sconfig.embedding_method in [:bow, :arora])
                @warn "$(sconfig.id) Defaulting embedding_method=$DEFAULT_EMBEDDING_METHOD."
                sconfig.embedding_method = DEFAULT_EMBEDDING_METHOD
            end
            # type of search model
            if !(sconfig.embedding_search_model in [:naive, :brutetree, :kdtree, :hnsw])
                @warn "$(sconfig.id) Defaulting embedding_search_model=$DEFAULT_EMBEDDING_SEARCH_MODEL."
                sconfig.embedding_search_model = DEFAULT_EMBEDDING_SEARCH_MODEL
            end
            # type of the embedding elements
            if !(sconfig.embedding_element_type in [:Float32, :Float64])
                @warn "$(sconfig.id) Defaulting embedding_element_type=$DEFAULT_EMBEDDING_ELEMENT_TYPE."
                sconfig.embedding_element_type = DEFAULT_EMBEDDING_ELEMENT_TYPE
            end
            # GloVe embeddings vocabulary (only for binary embedding files)
            if  sconfig.embeddings_library == :glove && sconfig.embeddings_kind == :binary
                if (sconfig.glove_vocabulary == nothing) ||
                   (sconfig.glove_vocabulary isa AbstractString &&
                    !isfile(sconfig.glove_vocabulary))
                    @warn """$(sconfig.id) Missing GloVe vocabulary file,
                             ignoring search configuration..."""
                    push!(removable, i)
                    continue
                end
            end
        end
    end
    # Remove search configs that have missing files
    deleteat!(search_configs, removable)
    isempty(search_configs) &&
        @error """The search configuration does not contain searchable entities.
                  Please review $filename, add entries or fix the configuration errors."""
    return search_configs
end

function load_search_configs(filenames::Vector{S}) where S<:AbstractString
    return vcat((load_search_configs(file) for file in filenames)...)
end



"""
    get_parsing_function(args...)

Function that generates a parsing function from its input arguments and
returns it.

# Arguments
  * `parser::Symbol` is the name of the parser
  * `parser_config::Union{Nothing, Dict}` can contain optional configuration data
    for the parser (for delimited parsers)
  * `header::Bool` whether the file has a header or not (for delimited files only)
  * `delimiter::String` the delimiting character (for delimited files only)
  * `globbing_pattern::String` globbing pattern for gathering file lists
    from directories (for directory parsers only)
  * `build_summary::Bool` whether to use a summary instead of the full document
    (for directory parsers only)
  * `summary_ns::Int` how many sentences to use in the summary (for directory
    parsers only)
  * `summarization_strip_flags::UInt32` flags used to strip text before summarization
    (for directory parsers only)
  * `show_progress::Bool` whether to show the progress when loading files

Note: `parser` must be in the keys of the `PARSER_CONFIGS` constant. The name
      of the data parsing function is created as: `:__parser_<parser>` so,
      the function name `:__parser_delimited_format_1` corresponds to the
      parser `:delimited_format_1`. The function must be defined apriori.
"""
function get_parsing_function(parser::Symbol,
                              parser_config::Union{Nothing, Dict},
                              header::Bool,
                              delimiter::String,
                              globbing_pattern::String,
                              build_summary::Bool,
                              summary_ns::Int,
                              summarization_strip_flags::UInt32,
                              show_progress::Bool)
    PREFIX = :__parser_
    # Construct the actual basic parsing function from parser name
    parsing_function  = eval(Symbol(PREFIX, parser))
    # Build and return parsing function (a nice closure)
    function parsing_closure(filename::String)
        return parsing_function(# Compulsory arguments for all parsers
                                filename,
                                parser_config,
                                # keyword arguments (not used by all parsers)
                                header=header,
                                delimiter=delimiter,
                                globbing_pattern=globbing_pattern,
                                build_summary=build_summary,
                                summary_ns=summary_ns,
                                summarization_strip_flags=
                                    summarization_strip_flags,
                                show_progress=show_progress)
    end
    return parsing_closure
end
