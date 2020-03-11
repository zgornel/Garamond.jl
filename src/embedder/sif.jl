"""
Smooth inverse frequency (SIF) structure for document embedding
using word vectors.

# References
  * [Arora et al. ICLR 2017, "A simple but tough-to-beat baseline for sentence embeddings"]
    (https://openreview.net/pdf?id=SyK00v5xx)
"""
struct SIFEmbedder{S,T} <: WordVectorsEmbedder{S,T}
    embeddings::EmbeddingsLibrary{S,T}
    lexicon::OrderedDict{S, Int}
    alpha::Float64
end

SIFEmbedder(embeddings::EmbeddingsLibrary{S,T};
            lexicon=OrderedDict{S, Int}(),
            alpha=DEFAULT_SIF_ALPHA,
            kwargs...) =
    SIFEmbedder(embeddings, lexicon, alpha)


# Dimensionality function
function dimensionality(embedder::SIFEmbedder)
    return size(embedder.embeddings)[1]
end


# Sentence embedding function
function sentences2vec(embedder::SIFEmbedder,
                       document_embedding::Vector{Matrix{T}};
                       embedded_words::Vector{Vector{S}}=[String[]],
                       kwargs...) where {S,T}
    isempty(document_embedding) && return zeros(T, dimensionality(embedder), 0)
    sif(document_embedding,
        embedder.lexicon,
        embedded_words,
        embedder.alpha,
        dimensionality(embedder))
end


"""
    sif(document_embedding, lexicon, embedded_words, alpha, dim)

Implementation of sentence embedding principled on subtracting the paragraph vector i.e.
principal vector of a sentence from the sentence's word embeddings.
"""
#TODO(Corneliu): Make the calculation of `alpha` automatic using some heuristic
function sif(document_embedding::Vector{Matrix{T}},
             lexicon::OrderedDict{String, Int},
             embedded_words::Vector{Vector{S}},
             alpha::Float64,
             dim::Int
            ) where {T<:AbstractFloat, S<:AbstractString}
    L = sum(values(lexicon))
    n = length(document_embedding)  # number of sentences in document
    X = zeros(T, dim, n)  # new document embedding
    α = T(alpha)
    # Loop over sentences
    for (i, s) in enumerate(document_embedding)
        p = [get(lexicon, word, eps(T))/L for word in embedded_words[i]]
        W = size(s,2)  # no. of words
        @inbounds for w in 1:W
            X[:,i] += 1/(length(s)) * (α/(α+p[w]) .* s[:,w])
        end
    end
    local u::Vector{T}
    try
        u₀, _, _ = tsvd(X, 1)
        u = vec(u₀)
    catch
        u₀, _, _ = svd(X)
        u =u₀[:, 1]
    end
    @inbounds @simd for i in 1:n
        X[:,i] -= (u*u') * X[:,i]
    end
    return X
end
