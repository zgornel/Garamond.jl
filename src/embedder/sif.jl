"""
Smooth inverse frequency (SIF) structure for document embedding
using word vectors.

# References
  * [Arora et al. ICLR 2017, "A simple but tough-to-beat baseline for sentence embeddings"]
    (https://openreview.net/pdf?id=SyK00v5xx)
"""
struct SIFEmbedder{T,S} <: WordVectorsEmbedder{T,S}
    embeddings::EmbeddingsLibrary{T,S}
    lexicon::OrderedDict{S, Int}
    alpha::T
    config::NamedTuple
end

SIFEmbedder(embeddings::EmbeddingsLibrary{T,S},
            config;
            lexicon=OrderedDict{S, Int}(),
            alpha=DEFAULT_SIF_ALPHA,
            kwargs...
            ) where {T,S} =
    SIFEmbedder(embeddings, lexicon, T(alpha), config)


# Dimensionality function
function dimensionality(embedder::SIFEmbedder)
    return size(embedder.embeddings)[1]
end


# Sentence embedding function
function sentences2vec(embedder::SIFEmbedder,
                       document_embedding::Vector{Matrix{T}};
                       embedded_words::Vector{Vector{S}}=[String[]],
                       kwargs...) where {T,S}
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
             alpha::T,
             dim::Int
            ) where {T<:AbstractFloat, S<:AbstractString}
    L = sum(values(lexicon))
    n = length(document_embedding)  # number of sentences in document
    X = zeros(T, dim, n)  # new document embedding
    # Loop over sentences
    for (i, s) in enumerate(document_embedding)
        p = [get(lexicon, word, eps(T))/L for word in embedded_words[i]]
        W = size(s,2)  # no. of words
        @inbounds for w in 1:W
            X[:,i] += 1/(length(s)) * (alpha/(alpha+p[w]) .* s[:,w])
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
