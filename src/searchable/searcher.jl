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
    prepared_document = entry2document(entry, srcher.config)
    embedded_document = document2vec(srcher.embedder,
                                     prepared_document,
                                     srcher.config.oov_policy;
                                     ngram_complexity=srcher.config.ngram_complexity)[1]
    index_operation = ifelse(position === :first, pushfirst!, push!)
    index_operation(srcher.index, embedded_document)
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
    prepared_documents = [entry2document(dbentry, config; flags=flags, language=language)
                          for dbentry in db_sorted_row_iterator(dbdata; id_key=id_key, rev=false)]

    # Build corpus
    crps = __build_corpus(prepared_documents, language, config.ngram_complexity)

    # Get embedder
    embedder = __build_embedder(crps, config; vectors_eltype=vectors_eltype)

    # Calculate embeddings for each document
    embedded_documents = documents2mat(embedder,
                                       prepared_documents,
                                       config.oov_policy;
                                       vectors_eltype=vectors_eltype,
                                       ngram_complexity=config.ngram_complexity)

    # Get search index type
    IndexType = SUPPORTED_INDEXES[config.search_index]

    # Build search index
    srchindex = IndexType(embedded_documents)

    # Build search tree (for suggestions)
    srchtree = __get_bktree(config.heuristic, crps)

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
    random_embedding = document2vec(embedder, rand(documents), oov_policy;
                                    ngram_complexity=ngram_complexity)[1]
    # pre-allocate
    embedded_documents = zeros(random_embedding,
                               vectors_eltype,
                               (dimensionality(embedder), length(documents)))
    # embed all
    for i in eachindex(documents)
        embedded_documents[:,i] = document2vec(embedder, documents[i], oov_policy;
                                               ngram_complexity=ngram_complexity)[1]
    end
    return embedded_documents
end


function __get_bktree(heuristic, crps)
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
const SUPPORTED_INDEXES = Dict(
    :naive => NaiveIndex,
    :brutetree => BruteTreeIndex,
    :kdtree => KDTreeIndex,
    :hnsw => HNSWIndex,
    :ivfadc => d->IVFIndex(d; kc=4, k=2, m=1), #TODO(Corneliu) Fix this hijacking (https://github.com/zgornel/Garamond.jl/issues/22)
    :noop => NoopIndex
   )


function __build_corpus(documents::Vector{Vector{String}},
                        language::Languages.Language,
                        ngram_complexity::Int)
    language_type = typeof(language)
    @assert language_type in SUPPORTED_LANGUAGES "Language $language_type is not supported"

    documents = Vector{StringDocument{String}}()
    for sentences in documents
        doc = StringDocument(join(sentences, " "))
        StringAnalysis.language!(doc, language)
        push!(documents, doc)
    end
    crps = Corpus(documents)

    # Update lexicon, inverse index
    update_lexicon!(crps, ngram_complexity)
    update_inverse_index!(crps, ngram_complexity)
    return crps
end


# TODO(Corneliu) Separate embeddings as well from searchers
# i.e. data, embeddings and indexes are separate an re-use each other
function __build_embedder(crps, config; vectors_eltype=vectors_eltype)
    if config.vectors in [:word2vec, :glove, :conceptnet, :compressed]
        embedder = __build_embedder(crps, vectors_eltype, config.vectors, config.embeddings_path,
                                    config.embeddings_kind, config.doc2vec_method,
                                    config.glove_vocabulary, config.sif_alpha,
                                    config.borep_dimension, config.borep_pooling_function,
                                    config.disc_ngram)
    elseif config.vectors in [:count, :tf, :tfidf, :bm25]
        embedder = __build_embedder(crps, vectors_eltype, config.ngram_complexity,
                                    config.vectors, config.vectors_transform,
                                    config.vectors_dimension,
                                    config.bm25_kappa, config.bm25_beta)
    end
end


function __build_embedder(crps::Corpus,
                          ::Type{T},
                          ngram_complexity::Int,
                          vectors::Symbol,
                          vectors_transform::Symbol,
                          vectors_dimension::Int,
                          bm25_kappa::Int,
                          bm25_beta::Float64
                         ) where T<:AbstractFloat
    # Initialize dtm
    dtm = DocumentTermMatrix{T}(crps, ngram_complexity=ngram_complexity)

    local model
    if vectors_transform == :none
        model = RPModel(dtm, k=0, stats=vectors,
                        ngram_complexity=ngram_complexity,
                        κ=bm25_kappa, β=bm25_beta)
    elseif vectors_transform == :rp
        model = RPModel(dtm, k=vectors_dimension, stats=vectors,
                        ngram_complexity=ngram_complexity,
                        κ=bm25_kappa, β=bm25_beta)
    elseif vectors_transform == :lsa
        model = LSAModel(dtm, k=vectors_dimension,
                         ngram_complexity=ngram_complexity,
                         stats=vectors, κ=bm25_kappa, β=bm25_beta)
    end

    # Construct embedder
    return DTVEmbedder(model)
end

function __build_embedder(crps::Corpus,
                          ::Type{T},
                          vectors::Symbol,
                          embeddings_path::String,
                          embeddings_kind::Symbol,
                          doc2vec_method::Symbol,
                          glove_vocabulary,
                          sif_alpha::Float64,
                          borep_dimension::Int,
                          borep_pooling_function::Symbol,
                          disc_ngram::Int
                         ) where T<:AbstractFloat
    # Read word embeddings
    local embeddings
    if vectors == :conceptnet
        embeddings = load_embeddings(embeddings_path,
                        languages=[Languages.English()],
                        data_type=T)
    elseif vectors == :word2vec
        embeddings = Word2Vec.wordvectors(embeddings_path, T,
                        kind=embeddings_kind,
                        normalize=false)
    elseif vectors == :glove
        embeddings = Glowe.wordvectors(embeddings_path, T,
                        kind=embeddings_kind,
                        vocabulary=glove_vocabulary,
                        normalize=false,
                        load_bias=false)
    elseif vectors == :compressed
        embeddings = EmbeddingsAnalysis.compressedwordvectors(
                        embeddings_path, T, kind=embeddings_kind)
    end

    # Construct embedder based on document2vec method
    if doc2vec_method == :boe
        return BOEEmbedder(embeddings)
    elseif doc2vec_method == :sif
        return SIFEmbedder(embeddings, create_lexicon(crps, 1), sif_alpha)
    elseif doc2vec_method == :borep
        return BOREPEmbedder(embeddings,
                    dim=borep_dimension,
                    pooling_function=borep_pooling_function)
    elseif doc2vec_method == :cpmean
        return CPMeanEmbedder(embeddings)
    elseif doc2vec_method == :disc
        return DisCEmbedder(embeddings, n=disc_ngram)
    end
end
