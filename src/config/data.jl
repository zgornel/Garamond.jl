########################################################
# Corpus Id's i.e. keys that uniquely identify corpora #
########################################################
struct StringId
    id::String
end

# Utils
random_hash_string() = string(hash(rand()), base=16)
random_string_id() = StringId(random_hash_string())

# Construct IDs
make_id(::Type{StringId}, id::T) where T<:AbstractString = StringId(String(id))
make_id(::Type{StringId}, id::T) where T<:Number = StringId(string(id))
make_id(::Type{StringId}, id::T) where T<:Nothing = random_string_id()


################
# SearchConfig #
################
"""
The search engine configuration object `SearchConfig` is used in building
search objects of type `Searcher` and to provide information about them to
other methods.
"""
mutable struct SearchConfig
    # general, data, processing
    id::StringId                    # searcher/corpus id
    id_aggregation::StringId        # aggregation id
    description::String             # description of the searcher
    enabled::Bool                   # whether to use the searcher in search or not
    config_path::String             # file path for the configuration file
    data_path::String               # file/directory path for the data (depends on what the parser accepts)
    parser::Function                # parser function used to obtain corpus
    parser_config::Union{Nothing,Dict}  # parser configuration
    language::String                # the corpus-level language (use "auto" for document-level autodetection)
    build_summary::Bool             # whether to summarize or not the documents
    summary_ns::Int                 # the number of sentences in the summary
    keep_data::Bool                 # whether to keep document data, metadata
    stem_words::Bool                # whether to stem data or not
    # vector representation (defines type of search i.e. classic, semantic, implicitly)
    vectors::Symbol                 # how document vectors are calculated i.e. :count, :tf, :tfidf, :bm25, :word2vec, :glove, :conceptnet
    vectors_transform::Symbol       # what transform to apply to the vectors i.e. :lsa, :rp, :none
    vectors_dimension::Int          # desired dimensionality after transform (ignored for word2vec approaches)
    vectors_eltype::Symbol          # type of the document vector elements
    search_index::Symbol            # type of the search index i.e. :naive, :kdtree, :hnsw
    embeddings_path::Union{Nothing, String}  # path to the embeddings file
    embeddings_kind::Symbol         # Type of the embedding file for Word2Vec, GloVe i.e. :text, :binary
    doc2vec_method::Symbol          # How to arrive at a single embedding from multiple i.e. :bow, :sif
    glove_vocabulary::Union{Nothing, String}  # Path to a GloVe-generated vocabulary file (only for binary embeddings)
    # other
    heuristic::Union{Nothing, Symbol} #search heuristic for suggesting mispelled words (nothing means no recommendations)
    # text stripping flags
    text_strip_flags::UInt32        # How to strip text data before indexing
    metadata_strip_flags::UInt32    # How to strip text metadata before indexing
    query_strip_flags::UInt32       # How to strip queries before searching
    summarization_strip_flags::UInt32 # How to strip text before summarization
    # parameters for embedding, scoring
    bm25_kappa::Int                 # κ parameter for BM25 (employed in BM25 only)
    bm25_beta::Float64              # β parameter for BM25 (employed in BM25 only)
    sif_alpha::Float64              # smooth inverse frequency α parameter (for 'sif' doc2vec method only)
    score_alpha::Float64            # score alpha (parameter for the scoring function)
    score_weight::Float64           # weight of scores of searcher (used in result aggregation)
    # cache parameters
    cache_directory::Union{Nothing, String}  # path to the DispatcherCache cache directory
    cache_compression::String       # DispatcherCache compression option
end

# Keyword argument constructor; all arguments sho
SearchConfig(;
          id=random_string_id(),
          id_aggregation=id,
          description="",
          enabled=false,
          config_path="",
          data_path="",
          parser=get_parsing_function(DEFAULT_PARSER,
                                      DEFAULT_PARSER_CONFIG,
                                      false,
                                      DEFAULT_DELIMITER,
                                      DEFAULT_GLOBBING_PATTERN,
                                      DEFAULT_LANGUAGE_STR,
                                      DEFAULT_BUILD_SUMMARY,
                                      DEFAULT_SUMMARY_NS,
                                      DEFAULT_SUMMARIZATION_STRIP_FLAGS,
                                      DEFAULT_SHOW_PROGRESS),
          parser_config=DEFAULT_PARSER_CONFIG,
          language=DEFAULT_LANGUAGE_STR,
          build_summary=DEFAULT_BUILD_SUMMARY,
          summary_ns=DEFAULT_SUMMARY_NS,
          keep_data=DEFAULT_KEEP_DATA,
          stem_words=DEFAULT_STEM_WORDS,
          vectors=DEFAULT_VECTORS,
          vectors_transform=DEFAULT_VECTORS_TRANSFORM,
          vectors_dimension=DEFAULT_VECTORS_DIMENSION,
          vectors_eltype=DEFAULT_VECTORS_ELTYPE,
          search_index=DEFAULT_SEARCH_INDEX,
          embeddings_path=nothing,
          embeddings_kind=DEFAULT_EMBEDDINGS_KIND,
          doc2vec_method=DEFAULT_DOC2VEC_METHOD,
          glove_vocabulary=nothing,
          heuristic=DEFAULT_HEURISTIC,
          text_strip_flags=DEFAULT_TEXT_STRIP_FLAGS,
          metadata_strip_flags=DEFAULT_METADATA_STRIP_FLAGS,
          query_strip_flags=DEFAULT_QUERY_STRIP_FLAGS,
          summarization_strip_flags=DEFAULT_SUMMARIZATION_STRIP_FLAGS,
          bm25_kappa=DEFAULT_BM25_KAPPA,
          bm25_beta=DEFAULT_BM25_BETA,
          sif_alpha=DEFAULT_SIF_ALPHA,
          score_alpha=DEFAULT_SCORE_ALPHA,
          score_weight=1.0,
          cache_directory=DEFAULT_CACHE_DIRECTORY,
          cache_compression=DEFAULT_CACHE_COMPRESSION) =
    # Call normal constructor
    SearchConfig(id, id_aggregation, description, enabled,
                 config_path, data_path, parser, parser_config,
                 language, build_summary, summary_ns, keep_data, stem_words,
                 vectors, vectors_transform, vectors_dimension, vectors_eltype,
                 search_index, embeddings_path, embeddings_kind, doc2vec_method,
                 glove_vocabulary, heuristic,
                 text_strip_flags, metadata_strip_flags,
                 query_strip_flags, summarization_strip_flags,
                 bm25_kappa, bm25_beta, sif_alpha,
                 score_alpha, score_weight,
                 cache_directory, cache_compression)


"""
    load_search_configs(filename)

Creates search configuration objects from a data configuration file
specified by `filename`. The file name can be either an `AbstractString`
with the path to the configuration file or a `Vector{AbstractString}`
specifying multiple configuration file paths. The function returns a
`Vector{SearchConfig}` that is used to build the `Searcher` objects.
"""
function load_search_configs(filename::AbstractString)

    # Read config (this should fail if config not found)
    local dict_configs::Vector{Dict{String, Any}}
    fullfilename = abspath(expanduser(filename))
    try
        dict_configs = JSON.parse(open(fid->read(fid, String), fullfilename))
    catch e
        @error "Could not parse data configuration file $fullfilename ($e). Exiting..."
        exit(-1)
    end

    # Create search configurations
    n = length(dict_configs)
    search_configs = [SearchConfig() for _ in 1:n]
    removable = Int[]  # search configs that have problems
    must_have_keys = ["vectors", "data_path", "parser"]

    for (i, (sconfig, dconfig)) in enumerate(zip(search_configs, dict_configs))
        if !all(map(key->haskey(dconfig, key), must_have_keys))
            @warn "Missing options from $must_have_keys in configuration $i. "*
                  "Ignoring search configuration..."
            push!(removable, i)  # if there is are no word embeddings, cannot search
            continue
        end
        # Get searcher parameter values (assigning default values when the case)
        try
            header = get(dconfig, "header", false)
            globbing_pattern = get(dconfig, "globbing_pattern", DEFAULT_GLOBBING_PATTERN)
            show_progress = get(dconfig, "show_progress", DEFAULT_SHOW_PROGRESS)
            delimiter = get(dconfig, "delimiter", DEFAULT_DELIMITER)
            sconfig.id = make_id(StringId, get(dconfig, "id", nothing))
            sconfig.id_aggregation = make_id(StringId, get(dconfig, "id_aggregation", sconfig.id.id))
            sconfig.description = get(dconfig, "description", "")
            sconfig.enabled = get(dconfig, "enabled", false)
            sconfig.config_path = fullfilename
            sconfig.data_path = postprocess_path(get(dconfig, "data_path", ""))
            sconfig.language = lowercase(get(dconfig, "language", DEFAULT_LANGUAGE_STR))
            sconfig.build_summary = Bool(get(dconfig, "build_summary", DEFAULT_BUILD_SUMMARY))
            sconfig.summary_ns = Int(get(dconfig, "summary_ns", DEFAULT_SUMMARY_NS))
            sconfig.keep_data = Bool(get(dconfig, "keep_data", DEFAULT_KEEP_DATA))
            sconfig.stem_words = Bool(get(dconfig, "stem_words", DEFAULT_STEM_WORDS))
            sconfig.vectors = Symbol(get(dconfig, "vectors", DEFAULT_VECTORS))
            sconfig.vectors_transform = Symbol(get(dconfig, "vectors_transform", DEFAULT_VECTORS_TRANSFORM))
            sconfig.vectors_dimension = Int(get(dconfig, "vectors_dimension", DEFAULT_VECTORS_DIMENSION))
            sconfig.vectors_eltype = Symbol(get(dconfig, "vectors_eltype", DEFAULT_VECTORS_ELTYPE))
            sconfig.search_index = Symbol(get(dconfig, "search_index", DEFAULT_SEARCH_INDEX))
            sconfig.embeddings_path = postprocess_path(get(dconfig, "embeddings_path", nothing))
            sconfig.embeddings_kind = Symbol(get(dconfig, "embeddings_kind", DEFAULT_EMBEDDINGS_KIND))
            sconfig.doc2vec_method = Symbol(get(dconfig, "doc2vec_method", DEFAULT_DOC2VEC_METHOD))
            sconfig.glove_vocabulary= get(dconfig, "glove_vocabulary", nothing)
            if haskey(dconfig, "heuristic")
                sconfig.heuristic = Symbol(dconfig["heuristic"])
            else
                sconfig.heuristic = DEFAULT_HEURISTIC
            end
            sconfig.text_strip_flags = UInt32(get(dconfig, "text_strip_flags", DEFAULT_TEXT_STRIP_FLAGS))
            sconfig.metadata_strip_flags = UInt32(get(dconfig, "metadata_strip_flags", DEFAULT_METADATA_STRIP_FLAGS))
            sconfig.query_strip_flags = UInt32(get(dconfig, "query_strip_flags", DEFAULT_QUERY_STRIP_FLAGS))
            sconfig.summarization_strip_flags = UInt32(get(dconfig, "summarization_strip_flags", DEFAULT_SUMMARIZATION_STRIP_FLAGS))
            sconfig.bm25_kappa = Int(get(dconfig, "bm25_kappa", DEFAULT_BM25_KAPPA))
            sconfig.bm25_beta = Float64(get(dconfig, "bm25_beta", DEFAULT_BM25_BETA))
            sconfig.sif_alpha = Float64(get(dconfig, "sif_alpha", DEFAULT_SIF_ALPHA))
            sconfig.score_alpha = Float64(get(dconfig, "score_alpha", DEFAULT_SCORE_ALPHA))
            sconfig.score_weight = Float64(get(dconfig, "score_weight", 1.0))
            sconfig.cache_directory = get(dconfig, "cache_directory", DEFAULT_CACHE_DIRECTORY)
            sconfig.cache_compression = get(dconfig, "cache_compression", DEFAULT_CACHE_COMPRESSION)
            # Construct parser (built last as requires other parameters)
            sconfig.parser_config = get(dconfig, "parser_config", DEFAULT_PARSER_CONFIG)
            sconfig.parser = get_parsing_function(Symbol(dconfig["parser"]),
                                                  sconfig.parser_config,
                                                  header,
                                                  delimiter,
                                                  globbing_pattern,
                                                  sconfig.language,
                                                  sconfig.build_summary,
                                                  sconfig.summary_ns,
                                                  sconfig.summarization_strip_flags,
                                                  show_progress)
            # Checks of the configuration parameter values;
            # data path
            if !isfile(sconfig.data_path) && !isdir(sconfig.data_path)
                @warn "$(sconfig.id) Missing data, ignoring search configuration..."
                push!(removable, i)  # if there is no data file, cannot search
                continue
            end
            # language
            if !(sconfig.language in [LANG_TO_STR[_lang] for _lang in SUPPORTED_LANGUAGES] ||
                 sconfig.language == "auto")
                @warn "$(sconfig.id) Defaulting language=$DEFAULT_LANGUAGE_STR."
                sconfig.language = DEFAULT_LANGUAGE_STR
            end
            # delimiter
            if !(typeof(delimiter) <: AbstractString) || length(delimiter) == 0
                @warn "$(sconfig.id) Defaulting delimiter=$DEFAULT_DELIMITER."
                sconfig.delimiter = DEFAULT_DELIMITER
            end
            # vectors
            if sconfig.vectors in [:count, :tf, :tfidf, :bm25]
                classic_search_approach = true  # classic search (including lsa, random projections)
            elseif sconfig.vectors in [:word2vec, :glove, :conceptnet]
                classic_search_approach = false  # semantic search
            else
                @warn "$(sconfig.id) Defaulting vectors=$DEFAULT_VECTORS."
                sconfig.vectors = DEFAULT_VECTORS  # bm25
                classic_search_approach = true
            end
            # vectors_eltype
            if !(sconfig.vectors_eltype in [:Float16, :Float32, :Float64])
                @warn "$(sconfig.id) Defaulting vectors_eltype=$DEFAULT_VECTORS_ELTYPE."
                sconfig.vectors_eltype= DEFAULT_VECTORS_ELTYPE
            end
            # search_index
            if !(sconfig.search_index in [:naive, :brutetree, :kdtree, :hnsw])
                @warn "$(sconfig.id) Defaulting search_index=$DEFAULT_SEARCH_INDEX."
                sconfig.search_index = DEFAULT_SEARCH_INDEX
            end
            # Classic search specific options
            if classic_search_approach
                # vectors_transform
                if !(sconfig.vectors_transform in [:none, :lsa, :rp])
                    @warn "$(sconfig.id) Defaulting vectors_transform=$DEFAULT_VECTORS_TRANSFORM."
                    sconfig.vectors_transform = DEFAULT_VECTORS_TRANSFORM
                else
                    # vectors_dimension
                    if sconfig.vectors_transform != :none && sconfig.vectors_dimension <= 0
                        @warn "$(sconfig.id) Defaulting vectors_dimension=$DEFAULT_VECTORS_DIMENSION."
                        sconfig.vectors_dimension = DEFAULT_VECTORS_DIMENSION
                    end
                end
                # embedings_path
                if sconfig.embeddings_path isa AbstractString && !isfile(sconfig.embeddings_path)
                    @warn "$(sconfig.id) Missing embeddings, ignoring search configuration..."
                    push!(removable, i)  # if there is are no word embeddings, cannot search
                    continue
                end
            else
                # Semantic search specific options
                # embedings_path
                if !isfile(sconfig.embeddings_path)
                    @warn "$(sconfig.id) Missing embeddings, ignoring search configuration..."
                    push!(removable, i)  # if there is are no word embeddings, cannot search
                    continue
                end
                # embeddings_kind
                if !(sconfig.embeddings_kind in [:binary, :text])
                    @warn "$(sconfig.id) Defaulting embeddings_kind=$DEFAULT_EMBEDDINGS_KIND."
                    sconfig.embeddings_kind = DEFAULT_EMBEDDINGS_KIND
                end
                # doc2vec_method
                if !(sconfig.doc2vec_method in [:bow, :sif])
                    @warn "$(sconfig.id) Defaulting doc2vec_method=$DEFAULT_DOC2VEC_METHOD."
                    sconfig.doc2vec_method = DEFAULT_DOC2VEC_METHOD
                end
                # GloVe embeddings vocabulary (only for binary embedding files)
                if sconfig.vectors == :glove && sconfig.embeddings_kind == :binary
                    if (sconfig.glove_vocabulary == nothing) ||
                            (sconfig.glove_vocabulary isa AbstractString && !isfile(sconfig.glove_vocabulary))
                        @warn "$(sconfig.id) Missing GloVe vocabulary file, ignoring search configuration..."
                        push!(removable, i)
                        continue
                    end
                end
            end
            # heuristic
            if !(typeof(sconfig.heuristic) <: Nothing) && !(sconfig.heuristic in keys(HEURISTIC_TO_DISTANCE))
                @warn "$(sconfig.id) Defaulting heuristic=$DEFAULT_HEURISTIC."
                sconfig.heuristic = DEFAULT_HEURISTIC
            end
            # cache directory - should work with any directory with write acess
            # cache compression
            if !(sconfig.cache_compression in ["bz2", "bzip2", "gz", "gzip", "none"])
                @warn "$(sconfig.id) Defaulting cache_compression=$DEFAULT_CACHE_COMPRESSION."
                sconfig.cache_compression = DEFAULT_CACHE_COMPRESSION
            end
        catch e
            @warn """$(sconfig.id) Could not correctly parse configuration in $(fullfilename).
                     Exception: $(e)
                     Ignoring search configuration..."""
            push!(removable, i)
        end
    end
    # Remove search configs that have missing files
    deleteat!(search_configs, removable)
    # Last checks
    if isempty(search_configs)
        @error """The search configuration does not contain searchable entities.
                  Please review $fullfilename, add entries or fix the
                  configuration errors. Exiting..."""
        exit(-1)
    else
        all_ids = Vector{StringId}()
        for config in search_configs
            if config.id in all_ids          # check id uniqueness
                @error """Multiple occurences of $(config.id) detected. Data id's
                          have to be unique. Please correct the error in $fullfilename.
                          Exiting..."""
                exit(-1)
            else
                push!(all_ids, config.id)
            end
        end
    end
    return search_configs
end

function load_search_configs(filenames::Vector{S}) where S<:AbstractString
    all_configs = Vector{SearchConfig}()
    all_ids = Vector{StringId}()
    for filename in filenames
        configs = load_search_configs(filename)  # read all configs from a file
        for config in configs
            if config.id in all_ids          # check id uniqueness
                @error """Multiple occurences of $(config.id) detected. Data id's
                          have to be unique. Please correct the error in $filename.
                          Exiting..."""
                exit(-1)
            else
                push!(all_ids, config.id)
                push!(all_configs, config)
            end
        end
    end
    return all_configs
end



# Small helper function that post-processes file paths
# (useful for handling backslash separators on Windows)
function postprocess_path(path)
    ppath = path
    if Sys.iswindows() && occursin("\\", path)
        ppath = replace(path, "\\"=>"/")
    end
    return ppath  # do nothing if not on Windows
end



"""
    read_searcher_configurations_json(srchers)

Returns a string containing a JSON dictionary where the keys are the paths
to the data configuration files for the loaded searchers and the values are
the searcher configurations contained in the respective files.
"""
function read_searcher_configurations_json(srchers)
    try
        files = unique(map(srcher->srcher.config.config_path, srchers))
        return JSON.json(Dict(file=>JSON.parse(read(file, String)) for file in files))
    catch e
        @warn "Could not return searcher configurations: $e. Returning empty string..."
        return ""
    end
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
  * `language::String` the plain English name of the language; use "auto" for
  document-level language autodetection
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
                              language::String,
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
                                language=language,
                                build_summary=build_summary,
                                summary_ns=summary_ns,
                                summarization_strip_flags=
                                    summarization_strip_flags,
                                show_progress=show_progress)
    end
    return parsing_closure
end
