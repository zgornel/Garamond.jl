"""
Bag-of-random-embedding-projections (BOREP) structure for
document embedding using word vectors.

# References
  * [Wieting, Kiela ICLR 2019, "No training required: Exploring random encoders
     for sentence classification"](https://arxiv.org/abs/1901.10444)
"""
struct BOREPEmbedder{S,T} <: WordVectorsEmbedder{S,T}
    embeddings::EmbeddingsLibrary{S,T}
    R::Matrix{T}
    fpool::Function
end

function BOREPEmbedder(embeddings::EmbeddingsLibrary{S,T};
              initialization::Symbol=:heuristic,
              pooling_function::Symbol=:sum
             ) where {T<:AbstractFloat, S<:AbstractString}
    # Check initialization option and generate random matrix
    d = size(embeddings)[1]  # number of vector components
    R = rand(T[1/sqrt(d), -1/sqrt(d)], 2048, d)

    # Check pooling function option anf generate pooling function
    fpool = x->vec(sum(x,dims=2))

    return BOREPEmbedder(embeddings, R, fpool)
end


# Sentence embedding function
function sentences2vec(embedder::BOREPEmbedder,
                       document_embedding::Vector{Matrix{T}};
                       kwargs...) where {S,T}
    n = length(document_embedding)
    dim = size(embedder.R, 1)
    X = zeros(T, dim, n)
    @inbounds @simd for i in 1:n
        X[:,i] = embedder.fpool(embedder.R * document_embedding[i])
    end
    return X
end
