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
    parse_configuration(filename)

Parses a data configuration file (JSON format) and returns a `NamedTuple`
that acts as a search environment configuration.

• Search environment options reference
    data_loader::Function           # 0 argument function that when called loads the data i.e. `dbdata`
    data_sampler::Function          # function that takes as input raw data and outputs a `dbdata` row
    id_key::Symbol                  # the name of the primary integer key in `dbdata`
    vectors_eltype::Type            # the type of the vectors, scores etc. has to be `<:AbstractFloat`
    searcher_configs::Vector{NamedTuple}  # the searcher configs (see reference below)
    config_path::String             # the path to the config

• Searcher options reference
    id::StringId                    # searcher id
    id_aggregation::StringId        # aggregation id
    description::String             # description of the searcher
    enabled::Bool                   # whether to use the searcher in search or not
    indexable_fields::Vector{Symbol}
    language::String                # the index-level language
    stem_words::Bool                # whether to stem data or not
    ngram_complexity::Int           # ngram complexity (i.e. max number of tokes for an n-gram)
    vectors::Symbol                 # how document vectors are calculated i.e. :count, :tf, :tfidf, :bm25, :word2vec, :glove, :conceptnet, :compressed
    vectors_transform::Symbol       # what transform to apply to the vectors i.e. :lsa, :rp, :none
    vectors_dimension::Int          # desired dimensionality after transform (ignored for word2vec approaches)
    search_index::Symbol            # type of the search index i.e. :naive, :kdtree, :hnsw
    search_index_arguments::Vector{Any}
    search_index_kwarguments::Dict{Symbol, Any}
    embeddings_path::Union{Nothing, String}  # path to the embeddings file
    embeddings_kind::Symbol         # Type of the embedding file for Word2Vec, GloVe i.e. :text, :binary
    doc2vec_method::Symbol          # How to arrive at a single embedding from multiple i.e. :boe, :sif etc.
    glove_vocabulary::Union{Nothing, String}  # Path to a GloVe-generated vocabulary file (only for binary embeddings)
    oov_policy::Symbol              # what to do with non-embeddable documents i.e. :none, :large_vector
    embedder_kwarguments::Dict{Symbol, Any}
    heuristic::Union{Nothing, Symbol} # search heuristic for suggesting mispelled words (nothing means no recommendations)
    text_strip_flags::UInt32        # How to strip text data before indexing
    query_strip_flags::UInt32       # How to strip queries before searching
    sif_alpha::Float64              # smooth inverse frequency α parameter (for 'sif' doc2vec method only)
    borep_dimension::Int            # output dimension for BOREP embedder
    borep_pooling_function::Symbol  # pooling function for the BOREP embedder
    disc_ngram::Int                 # DisC embedder ngram parameter
    score_alpha::Float64            # score alpha (parameter for the scoring function)
    score_weight::Float64           # weight of scores of searcher (used in result aggregation)
"""
function parse_configuration(filename::AbstractString)

    # Read config (this should fail if config not found)
    config_path = abspath(expanduser(filename))

    # Parse configuration file
    config = try
        JSON.parse(open(fid->read(fid, String), config_path))
    catch e
        @error "Could not parse configuration in $config_path ($e). Exiting..."
        exit(-1)
    end

    # Data loader
    data_loader_name = Symbol(get(config, "data_loader_name", DEFAULT_DATA_LOADER_NAME))
    data_loader_arguments = get(config, "data_loader_arguments", [])
    data_loader_kwarguments = Dict{Symbol, Any}(Symbol(k) => v for (k,v) in
                                   get(config, "data_loader_kwarguments", Dict{String,Any}()))
    data_loader_function = eval(data_loader_name)
    data_loader = ()->data_loader_function(data_loader_arguments...; pairs(data_loader_kwarguments)...)

    # Data sampler
    data_sampler_name = Symbol(get(config, "data_sampler_name", DEFAULT_DATA_SAMPLER_NAME))
    data_sampler = eval(data_sampler_name)

    # Read primary db key
    id_key = Symbol(get(config, "id_key", DEFAULT_DB_ID_KEY))

    # Create an environment id
    id_environment = make_id(StringId, get(config, "id", nothing))

    # Vectors element type
    vectors_eltype = try
        eval(Symbol(config["vectors_eltype"]))
    catch e
        @debug "Wrong or missing vectors eltype.\n$e\nDefaulting vectors_eltype=$DEFAULT_VECTORS_ELTYPE."
        DEFAULT_VECTORS_ELTYPE
    end

    # Searcher configs
    parsed_searcher_configs = config["searchers"]
    searcher_configs = []
    MUST_HAVE_KEYS = ["vectors"]

    for (i, dconfig) in enumerate(parsed_searcher_configs)
        if !all(map(key->haskey(dconfig, key), MUST_HAVE_KEYS))
            @warn "Missing keys from $MUST_HAVE_KEYS in configuration $i. Ignoring..."*
            continue
        end
        # Get searcher parameter values (assigning default values when the case)
        try
            _id = make_id(StringId, get(dconfig, "id", nothing))
            _id_aggregation = haskey(dconfig, "id_aggregation") ?
                                make_id(StringId, dconfig["id_aggregation"]) :
                                id_environment
            _description = get(dconfig, "description", "")
            _enabled = get(dconfig, "enabled", true)
            _indexable_fields = Symbol.(get(dconfig, "indexable_fields", DEFAULT_INDEXABLE_FIELDS))
            _language = lowercase(get(dconfig, "language", DEFAULT_LANGUAGE_STR))
            _stem_words = Bool(get(dconfig, "stem_words", DEFAULT_STEM_WORDS))
            _ngram_complexity = Int(get(dconfig, "ngram_complexity", DEFAULT_NGRAM_COMPLEXITY))
            _vectors = Symbol(get(dconfig, "vectors", DEFAULT_VECTORS))
            _vectors_transform = Symbol(get(dconfig, "vectors_transform", DEFAULT_VECTORS_TRANSFORM))
            _vectors_dimension = Int(get(dconfig, "vectors_dimension", DEFAULT_VECTORS_DIMENSION))
            _search_index = Symbol(get(dconfig, "search_index", DEFAULT_SEARCH_INDEX))
            _search_index_arguments = get(dconfig, "search_index_arguments", [])
            _search_index_kwarguments = try
                Dict{Symbol, Any}(Symbol(k)=>v for (k,v) in get(dconfig, "search_index_kwarguments", Dict{String, Any}()))
            catch
                Dict{Symbol,Any}()
            end
            _embeddings_path = postprocess_path(get(dconfig, "embeddings_path", nothing))
            _embeddings_kind = Symbol(get(dconfig, "embeddings_kind", DEFAULT_EMBEDDINGS_KIND))
            _doc2vec_method = Symbol(get(dconfig, "doc2vec_method", DEFAULT_DOC2VEC_METHOD))
            _glove_vocabulary = get(dconfig, "glove_vocabulary", nothing)
            _oov_policy = Symbol(get(dconfig, "oov_policy", DEFAULT_OOV_POLICY))
            _embedder_kwarguments = try
                Dict{Symbol, Any}(Symbol(k)=>v for (k,v) in get(dconfig, "embedder_kwarguments", Dict{String, Any}()))
            catch
                Dict{Symbol,Any}()
            end
            _heuristic = haskey(dconfig, "heuristic") ? Symbol(dconfig["heuristic"]) : _heuristic = DEFAULT_HEURISTIC
            _text_strip_flags = UInt32(get(dconfig, "text_strip_flags", DEFAULT_TEXT_STRIP_FLAGS))
            _query_strip_flags = UInt32(get(dconfig, "query_strip_flags", DEFAULT_QUERY_STRIP_FLAGS))
            _sif_alpha = Float64(get(dconfig, "sif_alpha", DEFAULT_SIF_ALPHA))
            _borep_dimension = Int(get(dconfig, "borep_dimension", DEFAULT_BOREP_DIMENSION))
            _borep_pooling_function = Symbol(get(dconfig, "borep_pooling_function", DEFAULT_BOREP_POOLING_FUNCTION))
            _disc_ngram = Int(get(dconfig, "disc_ngram", DEFAULT_DISC_NGRAM))
            _score_alpha = Float64(get(dconfig, "score_alpha", DEFAULT_SCORE_ALPHA))
            _score_weight = Float64(get(dconfig, "score_weight", 1.0))

            # Checks of the configuration parameter values;
            # language
            if !(_language in [LANG_TO_STR[l] for l in SUPPORTED_LANGUAGES])
                @warn "$(_id) Defaulting language=$DEFAULT_LANGUAGE_STR."
                _language = DEFAULT_LANGUAGE_STR
            end
            # ngram_complexity
            if _ngram_complexity < 1  # maybe put upper bound i.e. || ngram_complexity > 5
                @warn "$(_id) Defaulting ngram_complexity=$DEFAULT_NGRAM_COMPLEXITY."
                _ngram_complexity = DEFAULT_NGRAM_COMPLEXITY
            end
            # vectors
            if _vectors in [:count, :tf, :tfidf, :bm25]
                classic_search_approach = true  # classic search (including lsa, random projections)
            elseif _vectors in [:word2vec, :glove, :conceptnet, :compressed]
                classic_search_approach = false  # semantic search
            else
                @warn "$(_id) Defaulting vectors=$DEFAULT_VECTORS."
                _vectors = DEFAULT_VECTORS  # bm25
                classic_search_approach = true
            end
            # search_index
            if !(_search_index in [:naive, :brutetree, :kdtree, :hnsw, :ivfadc, :noop])
                @warn "$(_id) Defaulting search_index=$DEFAULT_SEARCH_INDEX."
                _search_index = DEFAULT_SEARCH_INDEX
            end
            # search_index_arguments
            if !(typeof(_search_index_arguments) <: AbstractVector)
                @warn "$(_id) Defaulting search_index_arguments=[]."
                _search_index_arguments=[]
            end
            # search_index_kwarguments
            if !(typeof(_search_index_kwarguments) <: Dict{Symbol})
                @warn "$(_id) Defaulting search_index_kwarguments=Dict{Symbol,Any}()."
                _search_index_kwarguments=Dict{Symbol,Any}()
            end
            # Classic search specific options
            if classic_search_approach
                # vectors_transform
                if !(_vectors_transform in [:none, :lsa, :rp])
                    @warn "$(_id) Defaulting vectors_transform=$DEFAULT_VECTORS_TRANSFORM."
                    _vectors_transform = DEFAULT_VECTORS_TRANSFORM
                else
                    # vectors_dimension
                    if _vectors_transform != :none && _vectors_dimension <= 0
                        @warn "$(_id) Defaulting vectors_dimension=$DEFAULT_VECTORS_DIMENSION."
                        _vectors_dimension = DEFAULT_VECTORS_DIMENSION
                    end
                end
                # embedings_path
                if _embeddings_path isa AbstractString && !isfile(_embeddings_path)
                    @warn "$(_id) Missing embeddings, ignoring search configuration..."
                    continue
                end
            else
                # Semantic search specific options
                # embedings_path
                if !isfile(_embeddings_path)
                    @warn "$(_id) Missing embeddings, ignoring search configuration..."
                    continue
                end
                # embeddings_kind
                if !(_embeddings_kind in [:binary, :text])
                    @warn "$(_id) Defaulting embeddings_kind=$DEFAULT_EMBEDDINGS_KIND."
                    _embeddings_kind = DEFAULT_EMBEDDINGS_KIND
                end
                # doc2vec_method
                if !(_doc2vec_method in [:boe, :sif, :borep, :cpmean, :disc])
                    @warn "$(_id) Defaulting doc2vec_method=$DEFAULT_DOC2VEC_METHOD."
                    _doc2vec_method = DEFAULT_DOC2VEC_METHOD
                end
                # GloVe embeddings vocabulary (only for binary embedding files)
                if _vectors == :glove && _embeddings_kind == :binary
                    if (_glove_vocabulary == nothing) ||
                            (_glove_vocabulary isa AbstractString && !isfile(_glove_vocabulary))
                        @warn "$(_id) Missing GloVe vocabulary file, ignoring search configuration..."
                        continue
                    end
                end
                if _doc2vec_method == :borep
                    if _borep_dimension <= 0
                        @warn "$(_id) Defaulting borep_dimension=$DEFAULT_BOREP_DIMENSION."
                        _borep_dimension = DEFAULT_BOREP_DIMENSION
                    end
                    if !(_borep_pooling_function in [:sum, :max])
                        @warn "$(_id) Defaulting borep_pooling_function=$DEFAULT_BOREP_POOLING_FUNCTION."
                        _borep_pooling_function = DEFAULT_BOREP_POOLING_FUNCTION
                    end
                elseif _doc2vec_method == :disc
                    if _disc_ngram <= 0
                        @warn "$(_id) Defaulting disc_ngram=$DEFAULT_DISC_NGRAM."
                        _disc_ngram = DEFAULT_DISC_NGRAM
                    end
                end
            end
            # oov_policy
            if !(_oov_policy in [:none, :large_vector])
                @warn "$(_id) Defaulting oov_policy=$DEFAULT_OOV_POLICY."
                _oov_policy = DEFAULT_OOV_POLICY
            end
            # embedder_kwarguments
            if !(typeof(_embedder_kwarguments) <: Dict{Symbol})
                @warn "$(_id) Defaulting embedder_kwarguments=Dict{Symbol,Any}()."
                _embedder_kwarguments=Dict{Symbol,Any}()
            end
            # heuristic
            if !(typeof(_heuristic) <: Nothing) && !(_heuristic in keys(HEURISTIC_TO_DISTANCE))
                @warn "$(_id) Defaulting heuristic=$DEFAULT_HEURISTIC."
                _heuristic = DEFAULT_HEURISTIC
            end

            push!(searcher_configs,
                    (id=_id,
                     id_aggregation=_id_aggregation,
                     description=_description,
                     enabled=_enabled,
                     indexable_fields=_indexable_fields,
                     language=_language,
                     stem_words=_stem_words,
                     ngram_complexity=_ngram_complexity,
                     vectors=_vectors,
                     vectors_transform=_vectors_transform,
                     vectors_dimension=_vectors_dimension,
                     search_index=_search_index,
                     search_index_arguments=_search_index_arguments,
                     search_index_kwarguments=_search_index_kwarguments,
                     embeddings_path=_embeddings_path,
                     embeddings_kind=_embeddings_kind,
                     doc2vec_method=_doc2vec_method,
                     glove_vocabulary=_glove_vocabulary,
                     oov_policy=_oov_policy,
                     embedder_kwarguments=_embedder_kwarguments,
                     heuristic=_heuristic,
                     text_strip_flags=_text_strip_flags,
                     query_strip_flags=_query_strip_flags,
                     sif_alpha=_sif_alpha,
                     borep_dimension=_borep_dimension,
                     borep_pooling_function=_borep_pooling_function,
                     disc_ngram=_disc_ngram,
                     score_alpha=_score_alpha,
                     score_weight=_score_weight))

        catch e
            @warn """$(_id) Could not correctly parse configuration in $(config_path).\n$(e)
                     Ignoring search configuration..."""
        end
    end

    # Last checks
    if isempty(searcher_configs)
        @error """The search configuration does not contain searchable entities.
                  Please review $config_path, add entries or fix the
                  configuration errors. Exiting..."""
        exit(-1)
    else
        all_ids = Vector{StringId}()
        for config in searcher_configs
            if config.id in all_ids          # check id uniqueness
                @error """Multiple occurences of $(config.id) detected. Data id's
                          have to be unique. Please correct the error in $config_path.
                          Exiting..."""
                exit(-1)
            else
                push!(all_ids, config.id)
            end
        end
    end

    return (data_loader=data_loader,
            data_sampler=data_sampler,
            id_key=id_key,
            vectors_eltype=vectors_eltype,
            searcher_configs=searcher_configs,
            config_path=config_path)
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
