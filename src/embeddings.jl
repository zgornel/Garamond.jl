######################
# Document Embedding #
######################
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


"""
    embed_document(embeddings_library, lexicon, document[; embedding_method])

Function to get from multiple sentencea to a document embedding.
The `embedding_method` option controls how multiple sentence embeddings
are combined into a single document embedding.
Avalilable options for `embedding_method`:
    :bow - calculates document embedding as the mean of the sentence embeddings
    :sif - smooth-inverse-frequency subtracts paragraph/phrase vector
           from each sentence embedding
"""
function embed_document(embeddings_library::Union{
                            ConceptNet{<:Languages.Language, <:AbstractString, T},
                            Word2Vec.WordVectors{<:AbstractString, T, <:Integer},
                            Glowe.WordVectors{<:AbstractString, T, <:Integer}},
                        lexicon::Dict{String, Int},
                        document::Vector{String};  # a vector of sentences
                        embedding_method::Symbol=DEFAULT_EMBEDDING_METHOD
                       ) where T<:AbstractFloat
    # Initializations
    n = length(document)
    m = size(embeddings_library)[1]  # number of vector components
    embedded_words = Vector{Vector{String}}(undef, n)
    sentence_embeddings = Vector{Matrix{T}}(undef, n)
    # Embed sentences individually
    @inbounds for i in 1:n
        words = tokenize_fast(document[i])
        _embs, _mtoks = embed_document(embeddings_library,
                                       words,
                                       keep_size=false,
                                       max_compound_word_length=1,
                                       wildcard_matching=true,
                                       print_matched_words=false)
        sentence_embeddings[i] = T.(_embs)
        embedded_words[i] = words[setdiff(1:length(words), _mtoks)]
    end
    # Remove empty embeddings
    embedded = map(!isempty, sentence_embeddings)
    sentence_embeddings = sentence_embeddings[embedded]
    embedded_words = embedded_words[embedded]
    # If nothing is embedded, return zeros
    isempty(sentence_embeddings) && return zeros(T, m)
    if embedding_method == :sif
        return squash(smooth_inverse_frequency(sentence_embeddings,
                                               lexicon,
                                               embedded_words))
    else
        return squash(squash.(sentence_embeddings),m)
    end
end


"""
    smooth_inverse_frequency(document_embedding, lexicon, embedded_words)

Small function that transforms a document embedding based on word frequencies subtracting the
paragraph vector i.e. principal vector from the word embeddings. Useful for transfer learning
i.e. use word embeddings trained in a different context than the one where the matching has to
occur.
[1] "A simple but tough-to-beat baseline for sentence embeddings", Arora et al. ICLR 2017
    (https://openreview.net/pdf?id=SyK00v5xx)
"""
#TODO(Corneliu): Make the calculation of `a` automatic using some heuristic
function smooth_inverse_frequency(document_embedding::Vector{Matrix{T}},
                                  lexicon::Dict{String, Int},
                                  embedded_words::Vector{Vector{S}}
                                 ) where {T<:AbstractFloat, S<:AbstractString}
    L = sum(values(lexicon))
    m = size(document_embedding[1],1)  # number of vector elements
    n = length(document_embedding)  # number of sentences in document
    X = zeros(T, m, n)  # new document embedding
    a = 1
    # Loop over sentences
    for (i, s) in enumerate(document_embedding)
        p = [get(lexicon, word, eps(T))/L for word in embedded_words[i]]
        W = size(s,2)  # no. of words
        @inbounds for w in 1:W
            X[:,i] += 1/(length(s)) * (a/(a+p[w]) .* s[:,w])
        end
    end
    u, _, _ = tsvd(X, 1)
    @inbounds @simd for i in 1:n
        X[:,i] -= u'u * X[:,i]
    end
    return X
end


"""
Function that embeds a document i.e. returns an embedding matrix, columns
are word embeddings, using the `Word2Vec` or `Glowe` WordVectors object.
The function has an identical signature as the one from the
`ConceptnetNumberbatch` package.
"""
function embed_document(word_vectors::Union{Word2Vec.WordVectors{S1,T,H},
                                            Glowe.WordVectors{S1,T,H}},
                        document_tokens::Vector{S2};
                        language=Languages.English(),           # not used
                        keep_size::Bool=true,
                        compound_word_separator::String="_",    # not used
                        max_compound_word_length::Int=1,        # not used
                        wildcard_matching::Bool=false,          # not used
                        print_matched_words::Bool=false,
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
function embed_document(conceptnet::ConceptNet{L,K,E},
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
