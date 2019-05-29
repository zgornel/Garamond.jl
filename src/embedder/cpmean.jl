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
end

function CPMEANEmbedder(embeddings::EmbeddingsLibrary{S,T};
                        powers::Vector{T}=T[-Inf, 0.0, 1.0, Inf],
                        znorm::Bool=true
                      ) where {T<:AbstractFloat, S<:AbstractString}
    return CPMEANEmbedder(embeddings, powers, znorm)
end


# Dimensionality function
function dimensionality(embedder::CPMEANEmbedder)
    # Embedding corresponding to all powers are
    # concatenated vertically
    return length(embedder.powers) * size(embedder.embeddings)[1]
end


# Sentence embedding function - returns a `embedder.dim`×1 matrix
function sentences2vec(embedder::CPMEANEmbedder,
                       document_embedding::Vector{Matrix{T}};
                       kwargs...) where {S,T}
    if isempty(document_embedding)
        return zeros(T, dimensionality(embedder), 0)
    else
        return concatenated_power_mean(document_embedding,
                    embedder.powers, embedder.znorm,
                    dimensionality(embedder))
    end
end

function concatenated_power_mean(document_embedding::Vector{Matrix{T}},
                                 powers::Vector{T},
                                 znorm::Bool,
                                 dim::Int
                                ) where {T<:AbstractFloat}
    #TODO(Corneliu): Review performance of the approach
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

function znormalize!(v)
    μ, σ = mean(v), std(v)
    v .= (v.-μ)./σ
end
