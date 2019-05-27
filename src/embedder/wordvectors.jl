abstract type WordVectorsEmbedder{S,T} <: AbstractEmbedder{S,T} end


"""
Constant that represents embeddings libraries used in text embedding.
"""
const EmbeddingsLibrary{S,T} = Union{
    ConceptNet{<:Languages.Language, S, T},
    Word2Vec.WordVectors{S, T, <:Integer},
    Glowe.WordVectors{S, T, <:Integer}
}


"""
Bag-of-embeddings (BOE) structure for document embedding using word vectors.
"""
struct BOEEmbedder{S,T} <: WordVectorsEmbedder{S,T}
    embeddings::EmbeddingsLibrary{S,T}
end


"""
Smooth inverse frequency (SIF) structure for document embedding
using word vectors.
"""
struct SIFEmbedder{S,T} <: WordVectorsEmbedder{S,T}
    embeddings::EmbeddingsLibrary{S,T}
    lexicon::OrderedDict{S, Int}
    alpha::Float64
end


"""
    document2vec(embedder, document)

Word-embeddings approach to document embedding. It embeds documents
using word embeddings libraries and some algorithm for combining
these (depending on the type of `embedder`).

# Arguments
  * `embedder::WordVectorsEmbedder` is the embedder
  * `document::Vector{String}` the document to be embedded,
     where each vector element corresponds to a sentence
"""
function document2vec(embedder::WordVectorsEmbedder{S,T},
                      document::Vector{String};
                      kwargs...  # for the unused arguments
                     ) where {S,T}
    # Initializations
    n = length(document)
    m = size(embedder.embeddings)[1]  # number of vector components
    embedded_words = Vector{Vector{String}}(undef, n)
    doc_word_embeddings = Vector{Matrix{T}}(undef, n)

    # Get word embeddings for each sentence
    @inbounds for i in 1:n
        words = tokenize(document[i], method=:fast)
        _embs, _mtoks = word_embeddings(embedder.embeddings,
                                        words,
                                        keep_size=false,
                                        max_compound_word_length=1,
                                        wildcard_matching=true,
                                        print_matched_words=false)
        doc_word_embeddings[i] = _embs
        embedded_words[i] = words[setdiff(1:length(words), _mtoks)]
    end

    # Remove empty embeddings
    filter!(!isempty, doc_word_embeddings)
    filter!(!isempty, embedded_words)

    # Create sentence embeddings
    isempty(doc_word_embeddings) && return zeros(T, m)  # If nothing is embedded, return zeros
    sentence_embeddings = sentences2vec(embedder, doc_word_embeddings,
                                embedded_words, dim=m)
    return squash(sentence_embeddings)
end


"""
    sentences2vec(embedder, document_embedding, embedded_words [;dim=0])

Returns a matrix of sentence embeddings from a vector of matrices containing
individual sentence word embeddings.

# Arguments
  * `embedder::WordVectorsEmbedder` is the embedder
  * `document_embedding::Vector{Matrix{AbstractFloat}}` are the document's
     word embeddings, where each element of the vector represents the
     embedding of a sentence (whith the matrix columns individual word
     embeddings)
  * `embedded_words::Vector{Vector{AbstractString}}` are the words in
     each sentence the were embedded (their order corresponds to the
     order of the matrix columns in `document_embedding`
  * `dim::Int` is the dimension of the word embeddings i.e. number of
     components in the word vector (default `0`)
"""
function sentences2vec(embedder::BOEEmbedder,
                       document_embedding::Vector{Matrix{T}},
                       embedded_words::Vector{Vector{S}};
                       dim::Int=0) where {S,T}
    n = length(document_embedding)
    X = zeros(T, dim, n)
    @inbounds @simd for i in 1:n
        X[:,i] = squash(document_embedding[i])
    end
    return X
end

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
    word_embeddings(word_vectors, document_tokens [;kwargs])

Returns a matrix corresponding to the word embeddings of `document_tokens`
as well as the indices of missing i.e. not-embedded tokens.

# Arguments
  * `word_vectors::EmbeddingsLibrary` wordvectors object; can be
     a `Word2Vec.WordVectors`, `Glowe.WordVectors` or `ConceptnetNumberbatch.ConceptNet`
  * `document_tokens::Vector{String}` the words to be embedded,
     where each vector element corresponds to a word

# Keyword arguments
  * `keep_size::Bool` a `false` value discards vectors for words not found
     while a `true` value (default) places a zero vector in the embeddings
     matrix
  * `print_matched_words::Bool` if `true`, the words that were and that were
     not embedded are printed (default `false`)
  * `kwargs...` the rest of the keyword arguments are `ConceptNet` specific
     and can be found by inspecting the help of `ConceptnetNumberbatch.embed_document`
"""
function word_embeddings(word_vectors::Union{Word2Vec.WordVectors{S1,T,H},
                                             Glowe.WordVectors{S1,T,H}},
                         document_tokens::Vector{S2};
                         keep_size::Bool=true,
                         print_matched_words::Bool=false,
                         kwargs...) where {S1<:AbstractString, T<:Real,
                                           H<:Integer, S2<:AbstractString}
    # Initializations
    n = size(word_vectors)[1]
    p = length(document_tokens)
    found_positions = Int[] # column positions in word embedding matrix of found tokens
    found_tokens = Int[]    # positions in the token vector on found tokens

    # Search for matching words (exact match)
    for (i, token) in enumerate(document_tokens)
        if haskey(word_vectors.vocab_hash, token)
            push!(found_positions, word_vectors.vocab_hash[token])
            push!(found_tokens, i)
        end
    end
    missing_tokens = setdiff(1:p, found_tokens)  # positions of tokens that were not found

    # Construct document structure
    m = ifelse(keep_size, p, length(found_tokens))
    embedding = zeros(T, n, m)
    for (pos, tok, j) in zip(found_positions, found_tokens, 1:m)
        embedding[:, ifelse(keep_size, tok, j)] = word_vectors.vectors[:, pos]
    end

    # Return document embedding and missing tokens
    if print_matched_words
        println("Embedded words: $(tokens[found_tokens])")
        println("Mismatched words: $(tokens[missing_tokens])")
    end
    return embedding, missing_tokens
end

# Replicate ConceptnetNumberbatch embed_document function
function word_embeddings(conceptnet::ConceptNet{L,K,E},
                         document_tokens::Vector{S};
                         language=Languages.English(),
                         keep_size::Bool=true,
                         compound_word_separator::String="_",
                         max_compound_word_length::Int=1,
                         wildcard_matching::Bool=false,
                         print_matched_words::Bool=false
                        ) where {L<:Language, K, E<:Real, S<:AbstractString}
    return ConceptnetNumberbatch.embed_document(conceptnet, document_tokens,
                language=language, keep_size=keep_size,
                compound_word_separator=compound_word_separator,
                max_compound_word_length=max_compound_word_length,
                wildcard_matching=wildcard_matching,
                print_matched_words=print_matched_words)
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


"""
    squash(m)

Function that creates a single mean vector from a matrix `m`
and performs some normalization operations as well.
"""
squash(m::Matrix{T}) where T<:AbstractFloat = begin
    # Calculate document embedding
    ##############################
    v = vec(sum(m, dims=2))
    return v./(norm(v,2)+eps(T))
end

"""
    squash(vv, m)

Function that creates a single mean vector from a vector of vectors `vv`
where each vector has a length `m` and performs some normalization
operations as well.
"""
squash(vv::Vector{Vector{T}}, m::Int) where T<:AbstractFloat = begin
    v = zeros(T,m)
    for w in vv
        v+= w
    end
    return v./(norm(v,2)+eps(T))
end
