"""
Concatenated-power-mean-embeddings (CPMEAN) structure for
document embedding using word vectors.

# References
  * [Rücklé et al. 2018 "Concatenated power mean word embeddings
     as universal cross-lingual sentence representations"](https://arxiv.org/abs/1803.01400a)
"""
struct CPMEANEmbedder{S,T} <: WordVectorsEmbedder{S,T}
    embeddings::EmbeddingsLibrary{S,T}
    powers::Vector{T}
    znorm::Bool
    dim::Int
end

function CPMEANEmbedder(embeddings::EmbeddingsLibrary{S,T};
                        powers::Vector{T}=T[-Inf, 1.0, Inf],
                        znorm::Bool=true
                      ) where {T<:AbstractFloat, S<:AbstractString}
    dim = length(powers) * size(embeddings)[1]
    return CPMEANEmbedder(embeddings, powers, znorm, dim)
end


# Sentence embedding function - returns a `embedder.dim`×1 matrix
function sentences2vec(embedder::CPMEANEmbedder,
                       document_embedding::Vector{Matrix{T}};
                       kwargs...) where {S,T}
    #TODO(Corneliu): Review performance of the approach
    emb = hcat(document_embedding...)
    n = size(emb, 2)  # total number of embedded words in all sentences
    m = size(emb, 1)  # embedding dimensionality
    X = zeros(T, embedder.dim, 1)
    i = 1
    @inbounds for p in embedder.powers
        if p == -Inf
            f = x->minimum(x, dims=2)
        elseif p == Inf
            f = x->maximum(x, dims=2)
        else
            f = x->(1/n .* sum(x.^p, dims=2)).^(1/p)
        end
        X[(i-1)*m+1:i*m, 1] = f(emb)
        embedder.znorm && znormalize!(X[(i-1)*m+1:i*m, 1])
        i+=1
    end
    return X
end

function znormalize!(v)
    μ, σ = mean(v), std(v)
    v .= (v.-μ)./σ
end
