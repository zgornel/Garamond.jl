# Main Embedder type, parametrized by S - typeof embedded object
# and T the type of Float of the vectors
abstract type AbstractEmbedder{T<:AbstractFloat,S}  end


"""
    document2vec(embedder, document [;isregex=false])

Embeds documents. The document representation is conceptually a vector
of sentences, the output is always a vector of floating point numbers.

# Arguments
  * `embedder::AbstractEmbedder` is the embedder
  * `document::Vector{AbstractString}` the document to be embedded,
     where each vector element corresponds to a sentence

# Keyword arguments
  * `isregex::Bool` a `false` value (default) specifies that the
     document tokens are to be matched exactly while a `true` value
     specifies that the tokens are to be matched partially
     (for DTV-based document embedding only)
"""
function document2vec(embedder::AbstractEmbedder, document::Vector{AbstractString}; kwargs...)
    # Prototype of the function only
    throw(ErrorException("`document2vec` is not implemented for the current arguments."))
end


"""
    sentences2vec(embedder, document_embedding, embedded_words [;dim=0])

Returns a matrix of sentence embeddings from a vector of matrices containing
individual sentence word embeddings. Used mostly for word-vectors based
embedders.

# Arguments
  * `embedder::AbstractEmbedder` is the embedder
  * `document_embedding::Vector{Matrix{AbstractFloat}}` are the document's
     word embeddings, where each element of the vector represents the
     embedding of a sentence (whith the matrix columns individual word
     embeddings)

# Keyword arguments
  * `dim::Int` is the dimension of the word embeddings i.e. number of
     components in the word vector (default `0`)
  * `embedded_words::Vector{Vector{AbstractString}}` are the words in
     each sentence the were embedded (their order corresponds to the
     order of the matrix columns in `document_embedding`

"""
function sentences2vec(embedder::AbstractEmbedder,
                       document_embedding::Vector{Matrix{AbstractFloat}};
                       kwargs...)
    # Prototype of the function only
    throw(ErrorException("`sentences2vec` is not implemented for the current arguments."))
end


function build_embedder(dbdata,
                        config;
                        vectors_eltype=DEFAULT_VECTORS_ELTYPE,
                        id_key=DEFAULT_ID_KEY)
    flags = config.text_strip_flags | (config.stem_words ? stem_words : 0x0)
    language = get(STR_TO_LANG, config.language, DEFAULT_LANGUAGE)()

    # Create documents
    documents = [join(dbentry2text(dbentry, config.embeddable_fields), " ")
              for dbentry in db_sorted_row_iterator(dbdata; id_key=id_key, rev=false)]

    # Build embedders
    if config.vectors in [:word2vec, :glove, :conceptnet, :compressed]
        return build_wv_embedder(documents, config; vectors_eltype=vectors_eltype)
    elseif config.vectors in [:count, :tf, :tfidf, :bm25]
        return build_dtv_embedder(documents, config; vectors_eltype=vectors_eltype)
    end
end


function build_dtv_embedder(documents, config; vectors_eltype=DEFAULT_VECTORS_ELTYPE)
    # Initialize dtm
    dtm = DocumentTermMatrix{vectors_eltype}(documents, ngram_complexity=config.ngram_complexity)
    mtype = RPModel
    k = 0
    config.vectors_transform === :none && true  # do nothing, mtype and k are initialized
    config.vectors_transform === :rp && (k=config.vectors_dimension)  # modify k
    config.vectors_transform === :lsa && (mtype=LSAModel, k=config.vectors_dimension)
    return DTVEmbedder(mtype,
                       dtm,
                       config;
                       # kwargs defaults from Garamond (override StringAnalysis defaults)
                       κ=DEFAULT_BM25_KAPPA,
                       β=DEFAULT_BM25_BETA,
                       # kwargs from config (overwritten by one below)
                       config.embedder_kwarguments...,
                       # specific kwargs from config (have highest priority)
                       k=k,
                       stats=config.vectors,
                       ngram_complexity=config.ngram_complexity)
end


function build_wv_embedder(documents, config; vectors_eltype=DEFAULT_VECTORS_ELTYPE)
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
        return BOEEmbedder(embeddings,
                           config;
                           config.embedder_kwarguments...);
    config.doc2vec_method === :sif &&
        return SIFEmbedder(embeddings,
                           config;
                           config.embedder_kwarguments...,
                           lexicon=create_lexicon(documents, 1),
                           alpha=config.sif_alpha)
    config.doc2vec_method === :borep &&
        return BOREPEmbedder(embeddings,
                             config;
                             config.embedder_kwarguments...,
                             dim=config.borep_dimension,
                             pooling_function=config.borep_pooling_function)
    config.doc2vec_method === :cpmean &&
        return CPMeanEmbedder(embeddings,
                              config;
                              config.embedder_kwarguments...)
    config.doc2vec_method === :disc &&
        return DisCEmbedder(embeddings,
                            config;
                            config.embedder_kwarguments...,
                            n=config.disc_ngram)
end


Base.zeros(::AbstractSparseArray, T, dims) = spzeros(T, dims...)

Base.zeros(::AbstractArray, T, dims) = zeros(T, dims...)


firstcol(m::AbstractMatrix) = m[:,1]


function embed!(out::AbstractMatrix{T},
                is_embedded::BitArray,
                embedder::AbstractEmbedder{T},
                entries;
                fields=nothing,
                kwargs...) where {T}
    flags = embedder.config.text_strip_flags | (embedder.config.stem_words ? stem_words : 0x0)
    language = get(STR_TO_LANG, embedder.config.language, DEFAULT_LANGUAGE)()
    documents = [dbentry2text(entry, fields) for entry in entries]
    for i in eachindex(documents)
        out[:,i], is_embedded[i] = document2vec(embedder,
                                        prepare.(documents[i], flags; language=language);
                                        kwargs...)
    end
    nothing
end


function embed(embedder::AbstractEmbedder, entries; fields=nothing, kwargs...)
    n = length(entries)
    embedded = preallocate_embeddings(embedder, n)
    isemb = falses(n)
    embed!(embedded, isemb, embedder, entries; fields=fields, kwargs...)
    return embedded, isemb
end


function preallocate_embeddings(embedder::AbstractEmbedder{T,S}, len) where {T,S}
    m, _ = document2vec(embedder, S[])
    p = similar(m, T, (dimensionality(embedder), len))
    fill!(p, zero(T))
    return p
end
