"""
Bag-of-embeddings (BOE) structure for document embedding using word vectors.
"""
struct BOEEmbedder{S,T} <: WordVectorsEmbedder{S,T}
    embeddings::EmbeddingsLibrary{S,T}
end


# Sentence embedding function
function sentences2vec(embedder::BOEEmbedder,
                       document_embedding::Vector{Matrix{T}};
                       kwargs...) where {S,T}
    n = length(document_embedding)
    m = size(embedder.embeddings)[1]
    X = zeros(T, m, n)
    @inbounds @simd for i in 1:n
        X[:,i] = squash(document_embedding[i])
    end
    return X
end
