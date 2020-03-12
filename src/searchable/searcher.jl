"""
    Search object. It contains all the indexed data and related
configuration that allows for searches to be performed.
"""
mutable struct Searcher{T<:AbstractFloat,
                        E<:AbstractEmbedder{String, T},
                        I<:AbstractIndex}
    data::Ref
    config::SearchConfig                        # most of what is not actual data
    embedder::E                                 # needed to embed query
    index::I                                    # indexed search data
    search_trees::BKTree{String}                # suggestion structure
end


# Useful methods
id(srcher::Searcher) = srcher.config.id

description(srcher::Searcher) = srcher.config.description

isenabled(srcher::Searcher) = srcher.config.enabled

disable!(srcher::Searcher) = begin
    srcher.config.enabled = false
    return srcher
end

enable!(srcher::Searcher) = begin
    srcher.config.enabled = true
    return srcher
end


# push!, pushfirst!, pop!, popfirst!, delete!
Base.push!(srcher::Searcher, entry) = pushinner!(srcher, entry, :last)

Base.pushfirst!(srcher::Searcher, entry) = pushinner!(srcher, entry, :first)

pushinner!(srcher::Searcher, entry, position::Symbol) = begin
    document = entry2document(entry, srcher.config)
    embedded = document2vec(srcher.embedder,
                            document,
                            srcher.config.oov_policy;
                            ngram_complexity=srcher.config.ngram_complexity)[1]
    index_operation = ifelse(position === :first, pushfirst!, push!)
    index_operation(srcher.index, embedded)
    nothing
end

Base.pop!(srcher::Searcher) = pop!(srcher.index)

Base.popfirst!(srcher::Searcher) = popfirst!(srcher.index)

Base.deleteat!(srcher::Searcher, pos) = delete_from_index!(srcher.index, pos)


# Indexing for vectors of searchers
function getindex(srchers::AbstractVector{Searcher}, an_id::StringId)
    idxs = Int[]
    for (i, srcher) in enumerate(srchers)
        isequal(id(srcher), an_id) && push!(idxs, i)
    end
    return srchers[idxs]
end

getindex(srchers::AbstractVector{Searcher}, an_id::String) = getindex(srchers, StringId(an_id))


"""
    build_searcher(dbdata, config)

Creates a Searcher from a searcher configuration `config::SearchConfig`.
"""
function build_searcher(dbdata,
                        config;
                        id_key=DEFAULT_DB_ID_KEY,
                        vectors_eltype=DEFAULT_VECTORS_ELTYPE)
    flags = config.text_strip_flags | (config.stem_words ? stem_words : 0x0)
    language = get(STR_TO_LANG, config.language, DEFAULT_LANGUAGE)()

    # Pre-process documents
    documents = [entry2document(dbentry, config; flags=flags, language=language)
                          for dbentry in db_sorted_row_iterator(dbdata; id_key=id_key, rev=false)]

    # Build corpus
    crps = build_corpus(documents, language, config.ngram_complexity)

    # Get embedder
    embedder = build_embedder(crps, config; vectors_eltype=vectors_eltype)

    # Calculate embeddings for each document
    embedded = documents2mat(embedder,
                             documents,
                             config.oov_policy;
                             vectors_eltype=vectors_eltype,
                             ngram_complexity=config.ngram_complexity)

    # Build search index
    indexer= build_indexer(config.search_index, config.search_index_args, config.search_index_kwargs)
    srchindex = indexer(embedded)

    # Build search tree (for suggestions)
    srchtree = build_bktree(config.heuristic, crps)

    # Build searcher
    srcher = Searcher(Ref(dbdata), config, embedder, srchindex, srchtree)

    @debug "* Loaded: $srcher."
    return srcher
end


entry2document(entry, config; flags=nothing, language=nothing) = begin
    flags === nothing && (flags=config.text_strip_flags | (config.stem_words ? stem_words : 0x0))
    language === nothing && (language=get(STR_TO_LANG, config.language, DEFAULT_LANGUAGE)())
    return prepare.(dbentry2text(entry, config.indexable_fields), flags; language=language)
end


Base.zeros(::AbstractSparseArray, T, dims) = spzeros(T, dims...)

Base.zeros(::AbstractArray, T, dims) = zeros(T, dims...)


function documents2mat(embedder,
                       documents,
                       oov_policy;
                       vectors_eltype=DEFAULT_VECTORS_ELTYPE,
                       ngram_complexity=DEFAULT_NGRAM_COMPLEXITY)
    # embed random document
    random_embedding = document2vec(embedder,
                                    rand(documents),
                                    oov_policy;
                                    ngram_complexity=ngram_complexity)[1]
    # pre-allocate
    embedded = zeros(random_embedding,
                     vectors_eltype,
                     (dimensionality(embedder), length(documents)))
    # embed all
    for i in eachindex(documents)
        embedded[:,i] = document2vec(embedder,
                                     documents[i],
                                     oov_policy;
                                     ngram_complexity=ngram_complexity)[1]
    end
    return embedded
end


function build_bktree(heuristic, crps)
    lexicon = create_lexicon(crps, 1)
    if heuristic != nothing
        distance = get(HEURISTIC_TO_DISTANCE, heuristic, DEFAULT_DISTANCE)
        fdist = (x,y) -> evaluate(distance, x, y)
        return BKTree(fdist, collect(keys(lexicon)))
    else
        return BKTree{String}()
    end
end


# Supported indexes name to type mapping
function build_indexer(index, args, kwargs)
    default_hnsw_kwargs = (:efconstruction=>100, :M=>16, :ef=>50)  # to ensure it works well
    default_ivfadc_kwargs = (:kc=>2, :k=>2, :m=>1)  # to ensure it works at all
    index === :naive && return d->NaiveIndex(d, args...; kwargs...)
    index === :brutetree && return d->BruteTreeIndex(d, args...; kwargs...)
    index === :kdtree && return d->KDTreeIndex(d, args...; kwargs...)
    index === :hnsw && return d->HNSWIndex(d, args...; default_hnsw_kwargs..., kwargs...)
    index === :ivfadc && return d->IVFIndex(d, args...; default_ivfadc_kwargs..., kwargs...)
    index === :noop && return d->NoopIndex(d, args...; kwargs...)
end


function build_corpus(documents::Vector{Vector{String}},
                      language::Languages.Language,
                      ngram_complexity::Int)
    language_type = typeof(language)
    @assert language_type in SUPPORTED_LANGUAGES "Language $language_type is not supported"

    _documents = Vector{StringDocument{String}}()
    for sentences in documents
        doc = StringDocument(join(sentences, " "))
        StringAnalysis.language!(doc, language)
        push!(_documents, doc)
    end
    crps = Corpus(_documents)

    # Update lexicon, inverse index
    update_lexicon!(crps, ngram_complexity)
    update_inverse_index!(crps, ngram_complexity)
    return crps
end


# TODO(Corneliu) Separate embeddings as well from searchers
# i.e. data, embeddings and indexes are separate an re-use each other
function build_embedder(crps, config; vectors_eltype=vectors_eltype)
    if config.vectors in [:word2vec, :glove, :conceptnet, :compressed]
        return build_wv_embedder(crps, config; vectors_eltype=vectors_eltype)
    elseif config.vectors in [:count, :tf, :tfidf, :bm25]
        return build_dtv_embedder(crps, config; vectors_eltype=vectors_eltype)
    end
end


function build_dtv_embedder(crps, config; vectors_eltype=DEFAULT_VECTORS_ELTYPE)
    # Initialize dtm
    dtm = DocumentTermMatrix{vectors_eltype}(crps, ngram_complexity=config.ngram_complexity)
    mtype = RPModel
    k = 0
    config.vectors_transform === :none && true  # do nothing, mtype and k are initialized
    config.vectors_transform === :rp && (k=config.vectors_dimension)  # modify k
    config.vectors_transform === :lsa && (mtype=LSAModel, k=config.vectors_dimension)
    return DTVEmbedder(mtype,
                       dtm;
                       # kwargs defaults from Garamond (override StringAnalysis defaults)
                       κ=DEFAULT_BM25_KAPPA,
                       β=DEFAULT_BM25_BETA,
                       # kwargs from config (overwritten by one below)
                       config.embedder_kwargs...,
                       # specific kwargs from config (have highest priority)
                       k=k,
                       stats=config.vectors,
                       ngram_complexity=config.ngram_complexity)
end


function build_wv_embedder(crps, config; vectors_eltype=DEFAULT_VECTORS_ELTYPE)
    # Read word embeddings
    local embeddings
    if config.vectors == :conceptnet
        embeddings = load_embeddings(config.embeddings_path,
                                     languages=[Languages.English()],
                                     data_type=vectors_eltype)
    elseif config.vectors == :word2vec
        embeddings = Word2Vec.wordvectors(config.embeddings_path,
                                          vectors_eltype,
                                          kind=config.embeddings_kind,
                                          normalize=false)
    elseif config.vectors == :glove
        embeddings = Glowe.wordvectors(config.embeddings_path,
                                       vectors_eltype,
                                       kind=config.embeddings_kind,
                                       vocabulary=config.glove_vocabulary,
                                       normalize=false,
                                       load_bias=false)
    elseif config.vectors == :compressed
        embeddings = EmbeddingsAnalysis.compressedwordvectors(
                        config.embeddings_path,
                        vectors_eltype,
                        kind=config.embeddings_kind)
    end

    # Construct embedder based on document2vec method
    config.doc2vec_method === :boe &&
        return BOEEmbedder(embeddings;
                           config.embedder_kwargs...)
    config.doc2vec_method === :sif &&
        return SIFEmbedder(embeddings;
                           config.embedder_kwargs...,
                           lexicon=create_lexicon(crps, 1),
                           alpha=config.sif_alpha)
    config.doc2vec_method === :borep &&
        return BOREPEmbedder(embeddings;
                             config.embedder_kwargs...,
                             dim=config.borep_dimension,
                             pooling_function=config.borep_pooling_function)
    config.doc2vec_method === :cpmean &&
        return CPMeanEmbedder(embeddings;
                              config.embedder_kwargs...)
    config.doc2vec_method === :disc &&
        return DisCEmbedder(embeddings;
                            config.embedder_kwargs...,
                            n=config.disc_ngram)
end
