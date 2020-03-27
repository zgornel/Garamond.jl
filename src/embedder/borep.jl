"""
Bag-of-random-embedding-projections (BOREP) structure for
document embedding using word vectors.

# References
  * [Wieting, Kiela ICLR 2019, "No training required: Exploring random encoders
     for sentence classification"](https://arxiv.org/abs/1901.10444)
"""
struct BOREPEmbedder{T,S} <: WordVectorsEmbedder{T,S}
    embeddings::EmbeddingsLibrary{T,S}
    R::Matrix{T}
    fpool::Function
    config::NamedTuple
end

function BOREPEmbedder(embeddings::EmbeddingsLibrary{T,S},
                       config;
                       dim=DEFAULT_BOREP_DIMENSION,
                       pooling_function=DEFAULT_BOREP_POOLING_FUNCTION,
                       initialization::Symbol=:heuristic,
                       kwargs...
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

    return BOREPEmbedder(embeddings, R, fpool, config)
end

# Dimensionality function
function dimensionality(embedder::BOREPEmbedder)
    # The final number of dimensions is given by
    # the dimension of the random space (i.e. number
    # of rows of the projection matrix)
    return size(embedder.R, 1)
end

# Sentence embedding function
function sentences2vec(embedder::BOREPEmbedder,
                       document_embedding::Vector{Matrix{T}};
                       kwargs...) where {T,S}
    n = length(document_embedding)
    X = zeros(T, dimensionality(embedder), n)
    @inbounds @simd for i in 1:n
        X[:,i] = embedder.fpool(embedder.R * document_embedding[i])
    end
    return X
end
