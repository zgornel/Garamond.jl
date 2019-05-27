abstract type WordVectorsEmbedder{S,T} <: AbstractEmbedder{S,T} end


const EmbeddingsLibrary{S,T} = Union{
    ConceptNet{<:Languages.Language, S, T},
    Word2Vec.WordVectors{S, T, <:Integer},
    Glowe.WordVectors{S, T, <:Integer}
}


struct BOEEmbedder{S,T} <: WordVectorsEmbedder{S,T}
    embeddings::EmbeddingsLibrary{S,T}
    lexicon::OrderedDict{S, Int}
end


function document2vec(embedder::WordVectorsEmbedder{S,T},
                      document::Vector{String};
                      embedding_method::Symbol=DEFAULT_DOC2VEC_METHOD,
                      sif_alpha::Float64=DEFAULT_SIF_ALPHA,
                      kwargs...  # for the unused arguments
                     ) where {S,T}
    # Initializations
    n = length(document)
    m = size(embedder.embeddings)[1]  # number of vector components
    embedded_words = Vector{Vector{String}}(undef, n)
    sentence_embeddings = Vector{Matrix{T}}(undef, n)
    # Embed sentences individually
    @inbounds for i in 1:n
        words = tokenize(document[i], method=:fast)
        _embs, _mtoks = word_embeddings(embedder.embeddings,
                                        words,
                                        keep_size=false,
                                        max_compound_word_length=1,
                                        wildcard_matching=true,
                                        print_matched_words=false)
        sentence_embeddings[i] = _embs
        embedded_words[i] = words[setdiff(1:length(words), _mtoks)]
    end
    # Remove empty embeddings
    filter!(!isempty, sentence_embeddings)
    filter!(!isempty, embedded_words)
    # If nothing is embedded, return zeros
    isempty(sentence_embeddings) && return zeros(T, m)
    if embedding_method == :sif
        return squash(smooth_inverse_frequency(
                        sentence_embeddings, embedder.lexicon,
                        embedded_words, alpha=sif_alpha))
    else
        return squash(squash.(sentence_embeddings), m)
    end
end



"""
Function that embeds a document i.e. returns an embedding matrix, columns
are word embeddings, using the `Word2Vec` or `Glowe` WordVectors object.
"""
function word_embeddings(word_vectors::Union{Word2Vec.WordVectors{S1,T,H},
                                             Glowe.WordVectors{S1,T,H}},
                        document_tokens::Vector{S2};
                        keep_size::Bool=true,
                        print_matched_words::Bool=false,
                        kwargs...
                       ) where {S1<:AbstractString, T<:Real, H<:Integer,
                                S2<:AbstractString}
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
#TODO(Corneliu): Make the calculation of `a` automatic using some heuristic
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
    v = vec(mean(m, dims=2))
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
