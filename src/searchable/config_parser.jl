"""
String ID object.
"""
struct StringId
    value::String
end

# Utils
random_hash_string() = string(hash(rand()), base=16)
random_string_id() = StringId(random_hash_string())

# Construct IDs
make_id(::Type{StringId}, value::T) where T<:AbstractString = StringId(String(value))
make_id(::Type{StringId}, value::T) where T<:Number = StringId(string(value))
make_id(::Type{StringId}, value::T) where T<:Nothing = random_string_id()


"""
The search engine configuration object `SearchConfig` is used in building
search objects of type `Searcher` and to provide information about them to
other methods.
"""
mutable struct SearchConfig
    # general, data, processing
    id::StringId                    # searcher id
    id_aggregation::StringId        # aggregation id
    description::String             # description of the searcher
    enabled::Bool                   # whether to use the searcher in search or not

    indexable_fields::Vector{Symbol}
    language::String                # the index-level language
    stem_words::Bool                # whether to stem data or not
    ngram_complexity::Int           # ngram complexity (i.e. max number of tokes for an n-gram)

    # vector representation (defines type of search i.e. classic, semantic, implicitly)
    vectors::Symbol                 # how document vectors are calculated i.e. :count, :tf, :tfidf, :bm25, :word2vec, :glove, :conceptnet, :compressed
    vectors_transform::Symbol       # what transform to apply to the vectors i.e. :lsa, :rp, :none
    vectors_dimension::Int          # desired dimensionality after transform (ignored for word2vec approaches)
    search_index::Symbol            # type of the search index i.e. :naive, :kdtree, :hnsw
    embeddings_path::Union{Nothing, String}  # path to the embeddings file
    embeddings_kind::Symbol         # Type of the embedding file for Word2Vec, GloVe i.e. :text, :binary
    doc2vec_method::Symbol          # How to arrive at a single embedding from multiple i.e. :boe, :sif etc.
    glove_vocabulary::Union{Nothing, String}  # Path to a GloVe-generated vocabulary file (only for binary embeddings)
    oov_policy::Symbol              # what to do with non-embeddable documents i.e. :none, :large_vector

    # other
    heuristic::Union{Nothing, Symbol} # search heuristic for suggesting mispelled words (nothing means no recommendations)

    # text stripping flags
    text_strip_flags::UInt32        # How to strip text data before indexing
    query_strip_flags::UInt32       # How to strip queries before searching

    # parameters for embedding, scoring
    bm25_kappa::Int                 # κ parameter for BM25 (employed in BM25 only)
    bm25_beta::Float64              # β parameter for BM25 (employed in BM25 only)
    sif_alpha::Float64              # smooth inverse frequency α parameter (for 'sif' doc2vec method only)
    borep_dimension::Int            # output dimension for BOREP embedder
    borep_pooling_function::Symbol  # pooling function for the BOREP embedder
    disc_ngram::Int                 # DisC embedder ngram parameter
    score_alpha::Float64            # score alpha (parameter for the scoring function)
    score_weight::Float64           # weight of scores of searcher (used in result aggregation)
end

# Keyword argument constructor; all arguments sho
SearchConfig(;
          id=random_string_id(),
          id_aggregation=id,
          description="",
          enabled=false,
          indexable_fields=DEFAULT_INDEXABLE_FIELDS,
          language=DEFAULT_LANGUAGE_STR,
          stem_words=DEFAULT_STEM_WORDS,
          ngram_complexity=DEFAULT_NGRAM_COMPLEXITY,
          vectors=DEFAULT_VECTORS,
          vectors_transform=DEFAULT_VECTORS_TRANSFORM,
          vectors_dimension=DEFAULT_VECTORS_DIMENSION,
          search_index=DEFAULT_SEARCH_INDEX,
          embeddings_path=nothing,
          embeddings_kind=DEFAULT_EMBEDDINGS_KIND,
          doc2vec_method=DEFAULT_DOC2VEC_METHOD,
          glove_vocabulary=nothing,
          oov_policy=DEFAULT_OOV_POLICY,
          heuristic=DEFAULT_HEURISTIC,
          text_strip_flags=DEFAULT_TEXT_STRIP_FLAGS,
          query_strip_flags=DEFAULT_QUERY_STRIP_FLAGS,
          bm25_kappa=DEFAULT_BM25_KAPPA,
          bm25_beta=DEFAULT_BM25_BETA,
          sif_alpha=DEFAULT_SIF_ALPHA,
          borep_dimension=DEFAULT_BOREP_DIMENSION,
          borep_pooling_function=DEFAULT_BOREP_POOLING_FUNCTION,
          disc_ngram=DEFAULT_DISC_NGRAM,
          score_alpha=DEFAULT_SCORE_ALPHA,
          score_weight=1.0)=
    # Call normal constructor
    SearchConfig(id, id_aggregation, description, enabled,
                 indexable_fields,
                 language, stem_words, ngram_complexity,
                 vectors, vectors_transform, vectors_dimension,
                 search_index, embeddings_path, embeddings_kind, doc2vec_method,
                 glove_vocabulary, oov_policy, heuristic,
                 text_strip_flags, query_strip_flags,
                 bm25_kappa, bm25_beta, sif_alpha,
                 borep_dimension, borep_pooling_function,
                 disc_ngram, score_alpha, score_weight)


"""
    parse_configuration(filename)

Creates search configuration objects from a data configuration file
specified by `filename`. The file name can be either an `AbstractString`
with the path to the configuration file or a `Vector{AbstractString}`
specifying multiple configuration file paths. The function returns a
`Vector{SearchConfig}` that is used to build the `Searcher` objects.
"""
function parse_configuration(filename::AbstractString)

    # Read config (this should fail if config not found)
    local config, dict_configs,
          data_loader_name, data_loader_arguments, data_loader_kwarguments,
          data_streamer_name, id_key, id_environment, vectors_eltype
    fullpathconfig = abspath(expanduser(filename))
    try
        # Parse configuration file
        config = JSON.parse(open(fid->read(fid, String), fullpathconfig))

        # Read separately individual searcher configurations
        dict_configs = config["searchers"]

        # Parse data loader name and arguments, keyword arguments
        data_loader_name = Symbol(get(config, "data_loader_name", DEFAULT_DATA_LOADER_NAME))
        data_loader_arguments = get(config, "data_loader_arguments", [])
        data_loader_kwarguments = Dict{Symbol, Any}(Symbol(k) => v for (k,v) in
                                       get(config, "data_loader_kwarguments", Dict{String,Any}()))

        # Parse data streamer name
        data_streamer_name = Symbol(get(config, "data_streamer_name", DEFAULT_DATA_STREAMER_NAME))

        # Read primary db key
        id_key = Symbol(get(config, "id_key", DEFAULT_DB_ID_KEY))

        # Create an environment id
        id_environment = make_id(StringId, get(config, "id", nothing))

        # Get vectors eltype
        vectors_eltype = try
            eval(Symbol(config["vectors_eltype"]))
        catch e
            @debug "Wrong or missing vectors eltype.\n$e\nDefaulting vectors_eltype=$DEFAULT_VECTORS_ELTYPE."
            DEFAULT_VECTORS_ELTYPE
        end

    catch e
        @error "Could not parse configuration in $fullpathconfig ($e). Exiting..."
        exit(-1)
    end

    # Construct data loader
    data_loader_function = eval(data_loader_name)
    data_loader_closure(args...;kwargs...) = () -> data_loader_function(args...;kwargs...)
    data_loader = data_loader_closure(data_loader_arguments...; pairs(data_loader_kwarguments)...)

    # Construct data loader
    data_streamer = eval(data_streamer_name)

    # Create search configurations
    n = length(dict_configs)
    searcher_configs = [SearchConfig() for _ in 1:n]
    removable = Int[]  # search configs that have problems
    must_have_keys = ["vectors"]

    for (i, (sconfig, dconfig)) in enumerate(zip(searcher_configs, dict_configs))
        if !all(map(key->haskey(dconfig, key), must_have_keys))
            @warn "Missing options from $must_have_keys in configuration $i. "*
                  "Ignoring search configuration..."
            push!(removable, i)  # if there is are no word embeddings, cannot search
            continue
        end
        # Get searcher parameter values (assigning default values when the case)
        try
            sconfig.id = make_id(StringId, get(dconfig, "id", nothing))
            id_aggregation = get(dconfig, "id_aggregation", nothing)
            if id_aggregation == nothing
                id_aggregation = id_environment
            else
                sconfig.id_aggregation = make_id(StringId, id_aggregation)
            end
            sconfig.description = get(dconfig, "description", "")
            sconfig.enabled = get(dconfig, "enabled", false)
            sconfig.indexable_fields = Symbol.(get(dconfig, "indexable_fields", DEFAULT_INDEXABLE_FIELDS))
            sconfig.language = lowercase(get(dconfig, "language", DEFAULT_LANGUAGE_STR))
            sconfig.stem_words = Bool(get(dconfig, "stem_words", DEFAULT_STEM_WORDS))
            sconfig.ngram_complexity = Int(get(dconfig, "ngram_complexity", DEFAULT_NGRAM_COMPLEXITY))
            sconfig.vectors = Symbol(get(dconfig, "vectors", DEFAULT_VECTORS))
            sconfig.vectors_transform = Symbol(get(dconfig, "vectors_transform", DEFAULT_VECTORS_TRANSFORM))
            sconfig.vectors_dimension = Int(get(dconfig, "vectors_dimension", DEFAULT_VECTORS_DIMENSION))
            sconfig.search_index = Symbol(get(dconfig, "search_index", DEFAULT_SEARCH_INDEX))
            sconfig.embeddings_path = postprocess_path(get(dconfig, "embeddings_path", nothing))
            sconfig.embeddings_kind = Symbol(get(dconfig, "embeddings_kind", DEFAULT_EMBEDDINGS_KIND))
            sconfig.doc2vec_method = Symbol(get(dconfig, "doc2vec_method", DEFAULT_DOC2VEC_METHOD))
            sconfig.glove_vocabulary = get(dconfig, "glove_vocabulary", nothing)
            sconfig.oov_policy = Symbol(get(dconfig, "oov_policy", DEFAULT_OOV_POLICY))
            if haskey(dconfig, "heuristic")
                sconfig.heuristic = Symbol(dconfig["heuristic"])
            else
                sconfig.heuristic = DEFAULT_HEURISTIC
            end
            sconfig.text_strip_flags = UInt32(get(dconfig, "text_strip_flags", DEFAULT_TEXT_STRIP_FLAGS))
            sconfig.query_strip_flags = UInt32(get(dconfig, "query_strip_flags", DEFAULT_QUERY_STRIP_FLAGS))
            sconfig.bm25_kappa = Int(get(dconfig, "bm25_kappa", DEFAULT_BM25_KAPPA))
            sconfig.bm25_beta = Float64(get(dconfig, "bm25_beta", DEFAULT_BM25_BETA))
            sconfig.sif_alpha = Float64(get(dconfig, "sif_alpha", DEFAULT_SIF_ALPHA))
            sconfig.borep_dimension = Int(get(dconfig, "borep_dimension", DEFAULT_BOREP_DIMENSION))
            sconfig.borep_pooling_function = Symbol(get(dconfig, "borep_pooling_function", DEFAULT_BOREP_POOLING_FUNCTION))
            sconfig.disc_ngram = Int(get(dconfig, "disc_ngram", DEFAULT_DISC_NGRAM))
            sconfig.score_alpha = Float64(get(dconfig, "score_alpha", DEFAULT_SCORE_ALPHA))
            sconfig.score_weight = Float64(get(dconfig, "score_weight", 1.0))

            # Checks of the configuration parameter values;
            # language
            if !(sconfig.language in [LANG_TO_STR[_lang] for _lang in SUPPORTED_LANGUAGES])
                @warn "$(sconfig.id) Defaulting language=$DEFAULT_LANGUAGE_STR."
                sconfig.language = DEFAULT_LANGUAGE_STR
            end
            # ngram_complexity
            if sconfig.ngram_complexity < 1  # maybe put upper bound i.e. || ngram_complexity > 5
                @warn "$(sconfig.id) Defaulting ngram_complexity=$DEFAULT_NGRAM_COMPLEXITY."
                sconfig.ngram_complexity = DEFAULT_NGRAM_COMPLEXITY
            end
            # vectors
            if sconfig.vectors in [:count, :tf, :tfidf, :bm25]
                classic_search_approach = true  # classic search (including lsa, random projections)
            elseif sconfig.vectors in [:word2vec, :glove, :conceptnet, :compressed]
                classic_search_approach = false  # semantic search
            else
                @warn "$(sconfig.id) Defaulting vectors=$DEFAULT_VECTORS."
                sconfig.vectors = DEFAULT_VECTORS  # bm25
                classic_search_approach = true
            end
            # search_index
            if !(sconfig.search_index in [:naive, :brutetree, :kdtree, :hnsw, :ivfadc])
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
                if !(sconfig.doc2vec_method in [:boe, :sif, :borep, :cpmean, :disc])
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
                if sconfig.doc2vec_method == :borep
                    if sconfig.borep_dimension <= 0
                        @warn "$(sconfig.id) Defaulting borep_dimension=$DEFAULT_BOREP_DIMENSION."
                        sconfig.borep_dimension = DEFAULT_BOREP_DIMENSION
                    end
                    if !(sconfig.borep_pooling_function in [:sum, :max])
                        @warn "$(sconfig.id) Defaulting borep_pooling_function=$DEFAULT_BOREP_POOLING_FUNCTION."
                        sconfig.borep_pooling_function = DEFAULT_BOREP_POOLING_FUNCTION
                    end
                elseif sconfig.doc2vec_method == :disc
                    if sconfig.disc_ngram <= 0
                        @warn "$(sconfig.id) Defaulting disc_ngram=$DEFAULT_DISC_NGRAM."
                        sconfig.disc_ngram = DEFAULT_DISC_NGRAM
                    end
                end
            end
            # oov_policy
            if !(sconfig.oov_policy in [:none, :large_vector])
                @warn "$(sconfig.id) Defaulting oov_policy=$DEFAULT_OOV_POLICY."
                sconfig.oov_policy = DEFAULT_OOV_POLICY
            end
            # heuristic
            if !(typeof(sconfig.heuristic) <: Nothing) && !(sconfig.heuristic in keys(HEURISTIC_TO_DISTANCE))
                @warn "$(sconfig.id) Defaulting heuristic=$DEFAULT_HEURISTIC."
                sconfig.heuristic = DEFAULT_HEURISTIC
            end
        catch e
            @warn """$(sconfig.id) Could not correctly parse configuration in $(fullpathconfig).
                     Exception: $(e)
                     Ignoring search configuration..."""
            push!(removable, i)
        end
    end

    # Remove search configs that have missing files
    deleteat!(searcher_configs, removable)
    # Last checks
    if isempty(searcher_configs)
        @error """The search configuration does not contain searchable entities.
                  Please review $fullpathconfig, add entries or fix the
                  configuration errors. Exiting..."""
        exit(-1)
    else
        all_ids = Vector{StringId}()
        for config in searcher_configs
            if config.id in all_ids          # check id uniqueness
                @error """Multiple occurences of $(config.id) detected. Data id's
                          have to be unique. Please correct the error in $fullpathconfig.
                          Exiting..."""
                exit(-1)
            else
                push!(all_ids, config.id)
            end
        end
    end

    return (data_loader=data_loader,
            data_streamer=data_streamer,
            id_key=id_key,
            vectors_eltype=vectors_eltype,
            searcher_configs=searcher_configs,
            config_path=fullpathconfig)
end


# Small helper function that post-processes file paths
# (useful for handling backslash separators on Windows)
function postprocess_path(path)
    ppath = path
    if path != nothing && Sys.iswindows()
        occursin("\\", path) && (ppath = replace(path, "\\"=>"/"))
    end
    return ppath  # do nothing if not on Windows
end


"""
    read_configuration_to_json(env)

Returns a JSON dictionary with the full configuration of the search environment.
"""
function read_configuration_to_json(env)
    try
        _config = JSON.parse(open(fid->read(fid, String), env.config_path))
        return JSON.json(Dict(env.config_path => _config))
    catch e
        @warn "Could not return search configuration. Returning empty string.\n$e"
        return ""
    end
end
