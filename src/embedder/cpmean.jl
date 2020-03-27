"""
Concatenated-power-mean-embeddings (CPMean) structure for
document embedding using word vectors.

# References
  * [Rücklé et al. 2018 "Concatenated power mean word embeddings
     as universal cross-lingual sentence representations"](https://arxiv.org/abs/1803.01400a)
"""
struct CPMeanEmbedder{T,S} <: WordVectorsEmbedder{T,S}
    embeddings::EmbeddingsLibrary{T,S}
    powers::Vector{T}
    znorm::Bool
    config::NamedTuple
end


function CPMeanEmbedder(embeddings::EmbeddingsLibrary{T,S},
                        config;
                        powers::Vector{T}=T[-Inf, 0.0, 1.0, Inf],
                        znorm::Bool=true,
                        kwargs...
                      ) where {T<:AbstractFloat, S<:AbstractString}
    return CPMeanEmbedder(embeddings, powers, znorm, config)
end


# Dimensionality function
function dimensionality(embedder::CPMeanEmbedder)
    # Embedding corresponding to all powers are
    # concatenated vertically
    return length(embedder.powers) * size(embedder.embeddings)[1]
end


# Sentence embedding function - returns a `embedder.dim`×1 matrix
function sentences2vec(embedder::CPMeanEmbedder,
                       document_embedding::Vector{Matrix{T}};
                       kwargs...) where {T,S}
    if isempty(document_embedding)
        return zeros(T, dimensionality(embedder), 0)
    else
        return __cpmean(document_embedding,
                        embedder.powers,
                        embedder.znorm,
                        dimensionality(embedder))
    end
end

function __cpmean(document_embedding::Vector{Matrix{T}},
                  powers::Vector{T},
                  znorm::Bool,
                  dim::Int
                 ) where {T<:AbstractFloat}
    embs = hcat(document_embedding...)
    n = size(embs, 2)  # total number of embedded words in all sentences
    m = size(embs, 1)  # embedding dimensionality
    X = zeros(T, dim, 1)

    # Construct various power mean functions
    # (they all work on matrices where the columns
    # are embeddings)
    dict_f = Dict{T, Function}(-Inf => (A,p)->minimum(A, dims=2),
                               Inf => (A,p)->maximum(A, dims=2),
                               0.0 => (A,p)->begin
                                            p = prod(A, dims=2);
                                            sign.(p).*abs.(p).^(1/n);
                                        end
                              )
    default_f = (A,p)->(1/n .* sum(A.^p, dims=2)).^(1/p)

    # Build document embedding
    i = 1
    @inbounds @simd for p in powers
        f = get(dict_f, p, default_f)
        Xp = view(X, (i-1)*m+1 : i*m, 1:1)
        Xp .= f(embs, p)
        znorm && znormalize!(Xp)
        i+=1
    end
    return X
end

function znormalize!(X::AbstractMatrix{T}) where {T}
    μ, σ = mean(X), std(X)
    X .= (X.-μ)./(σ+eps(T))
end
