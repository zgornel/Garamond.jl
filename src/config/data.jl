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
    # general, data, processing
    id::StringId                    # searcher/corpus id
    description::String             # description of the searcher
    enabled::Bool                   # whether to use the searcher in search or not
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
    search_model::Symbol            # type of the search model i.e. :naive, :kdtree, :hnsw
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
end

# Keyword argument constructor; all arguments sho
SearchConfig(;
          id=random_id(StringId),
          description="",
          enabled=false,
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
          search_model=DEFAULT_SEARCH_MODEL,
          embeddings_path=nothing,
          embeddings_kind=DEFAULT_EMBEDDINGS_KIND,
          doc2vec_method=DEFAULT_DOC2VEC_METHOD,
          glove_vocabulary=nothing,
          heuristic=DEFAULT_HEURISTIC,
          text_strip_flags=DEFAULT_TEXT_STRIP_FLAGS,
          metadata_strip_flags=DEFAULT_METADATA_STRIP_FLAGS,
          query_strip_flags=DEFAULT_QUERY_STRIP_FLAGS,
          summarization_strip_flags=DEFAULT_SUMMARIZATION_STRIP_FLAGS) =
    # Call normal constructor
    SearchConfig(id, description, enabled,
                 data_path, parser, parser_config,
                 language, build_summary, summary_ns, keep_data, stem_words,
                 vectors, vectors_transform, vectors_dimension, vectors_eltype,
                 search_model, embeddings_path, embeddings_kind, doc2vec_method,
                 glove_vocabulary, heuristic,
                 text_strip_flags, metadata_strip_flags,
                 query_strip_flags, summarization_strip_flags)


# Show method
Base.show(io::IO, sconfig::SearchConfig) = begin
    printstyled(io, "SearchConfig for $(sconfig.id)\n")
    printstyled(io, "`-enabled = ")
    printstyled(io, "$(sconfig.enabled)\n", bold=true)
    _tf = ""
    if sconfig.vectors in [:count, :tf, :tfidf, :b25]
        if sconfig.vectors_transform == :lsa
            _tf = " + LSA"
        elseif sconfig.vectors_transform == :rp
            _tf = " + random projection"
        end
    end
    printstyled(io, "  vectors = ")
    printstyled(io, "$(sconfig.vectors)$_tf", bold=true)
    printstyled(io, ", ")
    printstyled(io, "$(sconfig.vectors_eltype)\n", bold=true)
    printstyled(io, "  search_model = ")
    printstyled(io, "$(sconfig.search_model)\n", bold=true)
    printstyled(io, "  data_path = ")
    printstyled(io, "\"$(sconfig.data_path)\"\n", bold=true)
    if sconfig.embeddings_path != nothing
        printstyled(io, "  embeddings_path = ")
        printstyled(io, "\"$(sconfig.embeddings_path)\"\n", bold=true)
    end
end



"""
    load_search_configs(filename)

Function that creates search configurations from a data configuration file
specified by `filename`. It returns a `Vector{SearchConfig}` that is used
to build the `Searcher` objects with which search is performed.
"""
function load_search_configs(filename::AbstractString)
    # Read config (this should fail if config not found)
    local dict_configs::Vector{Dict{String, Any}}
    try
        dict_configs = JSON.parse(open(fid->read(fid, String), expanduser(filename)))
    catch
        @error "Could not read data configuration file $filename. Exiting..."
        exit(-1)
    end
    n = length(dict_configs)
    # Create search configurations
    search_configs = [SearchConfig() for _ in 1:n]
    removable = Int[]  # search configs that have problems
    must_have_keys = ["vectors", "data_path", "parser"]
    for (i, (sconfig, dconfig)) in enumerate(zip(search_configs, dict_configs))
        if !all(map(key->haskey(dconfig, key), must_have_keys))
            @warn "$(sconfig.id) Missing options from [$must_have_keys]. Ignoring search configuration..."
            push!(removable, i)  # if there is are no word embeddings, cannot search
            continue
        end
        # Get searcher parameter values (assigning default values when the case)
        header = get(dconfig, "header", false)
        globbing_pattern = get(dconfig, "globbing_pattern", DEFAULT_GLOBBING_PATTERN)
        show_progress = get(dconfig, "show_progress", DEFAULT_SHOW_PROGRESS)
        delimiter = get(dconfig, "delimiter", DEFAULT_DELIMITER)
        sconfig.id = make_id(StringId, get(dconfig, "id", randstring(10)))
        sconfig.description = get(dconfig, "description", "")
        sconfig.enabled = get(dconfig, "enabled", false)
        sconfig.data_path = get(dconfig, "data_path", "")
        sconfig.language = lowercase(get(dconfig, "language", DEFAULT_LANGUAGE_STR))
        sconfig.build_summary = get(dconfig, "build_summary", DEFAULT_BUILD_SUMMARY)
        sconfig.summary_ns = get(dconfig, "summary_ns", DEFAULT_SUMMARY_NS)
        sconfig.keep_data = get(dconfig, "keep_data", DEFAULT_KEEP_DATA)
        sconfig.stem_words = get(dconfig, "stem_words", DEFAULT_STEM_WORDS)
        sconfig.vectors = Symbol(get(dconfig, "vectors", DEFAULT_VECTORS))
        sconfig.vectors_transform = Symbol(get(dconfig, "vectors_transform", DEFAULT_VECTORS_TRANSFORM))
        sconfig.vectors_dimension = Int(get(dconfig, "vectors_dimension", DEFAULT_VECTORS_DIMENSION))
        sconfig.vectors_eltype = Symbol(get(dconfig, "vectors_eltype", DEFAULT_VECTORS_ELTYPE))
        sconfig.search_model = Symbol(get(dconfig, "search_model", DEFAULT_SEARCH_MODEL))
        sconfig.embeddings_path = get(dconfig, "embeddings_path", nothing)
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
        # No checks performed for:
        # - id (always works)
        # - description (always works)
        # - enabled (must fail if wrong)
        # - parser (must fail if wrong)
        # - parser_config (must fail if wrong)
        # - globbing_pattern (must fail if wrong)
        # - text data/metadata/query/summarization flags (must fail if wrong)
        ###
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
        # build_summary
        if !(typeof(sconfig.build_summary) <: Bool)
            @warn "$(sconfig.id) Defaulting build_summary=$DEFAULT_BUILD_SUMMARY."
            sconfig.build_summary = DEFAULT_BUILD_SUMMARY
        end
        # summary_ns i.e. the number of sentences in a summary
        if !(typeof(sconfig.summary_ns) <: Integer) || sconfig.summary_ns <= 0
            @warn "$(sconfig.id) Defaulting summary_ns=$DEFAULT_SUMMARY_NS."
            sconfig.summary_ns = DEFAULT_SUMMARY_NS
        end
        # keep_data
        if !(typeof(sconfig.keep_data) <: Bool)
            @warn "$(sconfig.id) Defaulting keep_data=$DEFAULT_KEEP_DATA."
            sconfig.keep_data = DEFAULT_KEEP_DATA
        end
        # stem_words
        if !(typeof(sconfig.stem_words) <: Bool)
            @warn "$(sconfig.id) Defaulting stem_words=$DEFAULT_STEM_WORDS."
            sconfig.stem_words = DEFAULT_STEM_WORDS
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
        if !(sconfig.vectors_eltype in [:Float32, :Float64])
            @warn "$(sconfig.id) Defaulting vectors_eltype=$DEFAULT_VECTORS_ELTYPE."
            sconfig.vectors_eltype= DEFAULT_VECTORS_ELTYPE
        end
        # search_model
        if !(sconfig.search_model in [:naive, :brutetree, :kdtree, :hnsw])
            @warn "$(sconfig.id) Defaulting search_model=$DEFAULT_SEARCH_MODEL."
            sconfig.search_model = DEFAULT_SEARCH_MODEL
        end
        # Classic search specific options
        if classic_search_approach
            # vectors_transform
            if !(sconfig.vectors_transform in [:none, :lsa, :rp])
                @warn "$(sconfig.id) Defaulting vectors_transform=$DEFAULT_VECTORS_TRANSFORM."
                sconfig.vectors_transform = DEFAULT_VECTORS_TRANSFORM
            else
                # vectors_dimension
                if sconfig.vectors_dimension <= 0
                    @warn "$(sconfig.id) Defaulting vectors_dimension=$DEFAULT_VECTORS_DIMENSION."
                    sconfig.vectors_dimension = DEFAULT_VECTORS_DIMENSION
                end
            end
            # embedings_path
            if (typeof(sconfig.embeddings_path) <: AbstractString) && !isfile(sconfig.embeddings_path)
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
            @warn "$(sconfig.id) Defaulting heuristic=nothing."
            sconfig.heuristic = DEFAULT_HEURISTIC
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
