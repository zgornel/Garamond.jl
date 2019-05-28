"""
Bag-of-embeddings (BOE) structure for document embedding using word vectors.
"""
struct BOEEmbedder{S,T} <: WordVectorsEmbedder{S,T}
    embeddings::EmbeddingsLibrary{S,T}
end


# Sentence embedding function
function sentences2vec(embedder::BOEEmbedder,
                       document_embedding::Vector{Matrix{T}};
                       dim::Int=0,
                       kwargs...) where {S,T}
    n = length(document_embedding)
    X = zeros(T, dim, n)
    @inbounds @simd for i in 1:n
        X[:,i] = squash(document_embedding[i])
    end
    return X
end
