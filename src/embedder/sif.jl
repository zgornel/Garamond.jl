"""
Smooth inverse frequency (SIF) structure for document embedding
using word vectors.
"""
struct SIFEmbedder{S,T} <: WordVectorsEmbedder{S,T}
    embeddings::EmbeddingsLibrary{S,T}
    lexicon::OrderedDict{S, Int}
    alpha::Float64
end


# Sentence embedding function
function sentences2vec(embedder::SIFEmbedder,
                       document_embedding::Vector{Matrix{T}},
                       embedded_words::Vector{Vector{S}};
                       dim::Int=0) where {S,T}
    smooth_inverse_frequency(document_embedding,
                             embedder.lexicon,
                             embedded_words,
                             alpha=embedder.alpha)
end


"""
    smooth_inverse_frequency(document_embedding, lexicon, embedded_words, alpha=DEFAULT_SIF_ALPHA)

Implementation of sentence embedding principled on subtracting the paragraph vector i.e.
principal vector of a sentence from the sentence's word embeddings.

# References
* [Arora et a. ICLR 2017, "A simple but tough-to-beat baseline for sentence embeddings"]
(https://openreview.net/pdf?id=SyK00v5xx)
"""
#TODO(Corneliu): Make the calculation of `alpha` automatic using some heuristic
function smooth_inverse_frequency(document_embedding::Vector{Matrix{T}},
                                  lexicon::OrderedDict{String, Int},
                                  embedded_words::Vector{Vector{S}};
                                  alpha::Float64=DEFAULT_SIF_ALPHA
                                 ) where {T<:AbstractFloat, S<:AbstractString}
    L = sum(values(lexicon))
    m = size(document_embedding[1],1)  # number of vector elements
    n = length(document_embedding)  # number of sentences in document
    X = zeros(T, m, n)  # new document embedding
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
