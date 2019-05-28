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
    dim::Int
end

function BOREPEmbedder(embeddings::EmbeddingsLibrary{S,T};
                       dim::Int=2048,
                       initialization::Symbol=:heuristic,
                       pooling_function::Symbol=:sum
                      ) where {T<:AbstractFloat, S<:AbstractString}
    # Check initialization option and generate random matrix
    d = size(embeddings)[1]  # number of vector components
    if initialization == :heuristic
        R = rand(T[-1/sqrt(d), 1/sqrt(d)], dim, d)
    elseif initialization == :uniform
        R = rand(T[-0.1, 0.1], dim, d)
    elseif initialization == :normal
        R = randn(T, dim, d)
    end

    # Check pooling function option anf generate pooling function
    if pooling_function == :sum
        fpool = x->vec(sum(x, dims=2))
    elseif pooling_function == :max
        fpool = x->vec(maximum(x, dims=2))
    end

    return BOREPEmbedder(embeddings, R, fpool, dim)
end


# Sentence embedding function
function sentences2vec(embedder::BOREPEmbedder,
                       document_embedding::Vector{Matrix{T}};
                       kwargs...) where {S,T}
    n = length(document_embedding)
    X = zeros(T, embedder.dim, n)
    @inbounds @simd for i in 1:n
        X[:,i] = embedder.fpool(embedder.R * document_embedding[i])
    end
    return X
end
