"""
Bag-of-embeddings (BOE) structure for document embedding using word vectors.
"""
struct BOEEmbedder{T,S} <: WordVectorsEmbedder{T,S}
    embeddings::EmbeddingsLibrary{T,S}
    config::NamedTuple
end

BOEEmbedder(embeddings, config; kwargs...) = BOEEmbedder(embeddings, config)


# Dimensionality function
function dimensionality(embedder::BOEEmbedder)
    return size(embedder.embeddings)[1]
end


# Sentence embedding function
function sentences2vec(embedder::BOEEmbedder{T,S},
                       document_embedding::Vector{Matrix{T}};
                       kwargs...) where {T,S}
    n = length(document_embedding)
    X = zeros(T, dimensionality(embedder), n)
    @inbounds @simd for i in 1:n
        X[:,i] = squash(document_embedding[i])
    end
    return X
end
