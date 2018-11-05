######################################
# Word embeddings related structures #
######################################
abstract type AbstractEmbeddingModel <: AbstractSearchData
end

struct NaiveEmbeddingModel{E} <: AbstractEmbeddingModel
    data::Matrix{E}
end


struct BruteTreeEmbeddingModel{A,D} <: AbstractEmbeddingModel
    tree::BruteTree{A,D}  # Array, Distance and Element types
end

BruteTreeEmbeddingModel(data::AbstractMatrix) =
    BruteTreeEmbeddingModel(BruteTree(data))


struct KDTreeEmbeddingModel{A,D} <: AbstractEmbeddingModel
    tree::KDTree{A,D}
end

KDTreeEmbeddingModel(data::AbstractMatrix) =
    KDTreeEmbeddingModel(KDTree(data))

struct HNSWEmbeddingModel{I,E,A,D} <: AbstractEmbeddingModel
    tree::HierarchicalNSW{I,E,A,D}
end

HNSWEmbeddingModel(data::AbstractMatrix) = begin
    _data = [data[:,i] for i in 1:size(data,2)]
    hnsw = HierarchicalNSW(_data;
                           efConstruction=100,
                           M=16,
                           ef=50)
    add_to_graph!(hnsw)
    return HNSWEmbeddingModel(hnsw)
end



# Nearest neighbor search methods
function search(model::NaiveEmbeddingModel{E}, point::Vector{E}, k::Int) where
        E<:AbstractFloat
    # Cosine similarity
    scores = (model.data)'*point
    idxs = sortperm(scores, rev=true)[1:k]
    return (idxs, scores[idxs])
end

function search(model::BruteTreeEmbeddingModel{A,D}, point::AbstractVector, k::Int) where
        {A<:AbstractArray, D<:Metric}
    # Uses Euclidean distance by default
    idxs, scores = knn(model.tree, point, k, true)
    return idxs, 1 ./ (scores .+ eps())
end

function search(model::KDTreeEmbeddingModel{A,D}, point::AbstractVector, k::Int) where
        {A<:AbstractArray, D<:Metric}
    # Uses Euclidean distance by default
    idxs, scores = knn(model.tree, point, k, true)
    return idxs, 1 ./ (scores .+ eps())
end

function search(model::HNSWEmbeddingModel{I,E,A,D}, point::AbstractVector, k::Int) where
        {I<:Unsigned, E<:Real, A<:AbstractArray, D<:Metric}
    # Uses Euclidean distance by default
    idxs, scores = knn_search(model.tree, point, k)
    return Int.(idxs), 1 ./ (scores .+ eps())
end



# Length methods
length(model::NaiveEmbeddingModel) = size(model.data, 2)
length(model::BruteTreeEmbeddingModel) = length(model.tree.data)
length(model::KDTreeEmbeddingModel) = length(model.tree.data)
length(model::HNSWEmbeddingModel) = length(model.tree.data)


######################
# Document Embedding #
######################
"""
Function that creates a single mean vector from a vector or matrix.
"""
squash(m::AbstractArray) = begin
    # Calculate document embedding
    ##############################
    v = vec(mean(m, dims=2))
    return v./(norm(v,2)+eps())
end



"""
    extract_tokens(doc)

Tokenizes various types of documents. Works for `AbstractString`,
Vector{AbstractString} and `TextAnalysis.jl` documents.
"""
extract_tokens(doc::NGramDocument) = String.(collect(keys(doc.ngrams)))
extract_tokens(doc::StringDocument) = String.(tokenize_for_conceptnet(doc.text))
extract_tokens(doc::AbstractString) = String.(tokenize_for_conceptnet(doc))
extract_tokens(doc::Vector{S} where S<:AbstractString) = String.(doc)



"""
    embed_document(embeddings_library, lexicon, doc[; embeddings_method])

Function to get from multiple word-embeddings to a document embedding.
The `embedding_method` option controls how multiple word embeddings
are combined into a single document embedding. Avalilable options:
    :bow - calculate document embedding as the mean of the word embeddings
    :arora - subtract paragraph/phrase vector [not working properly unless full documents are used]
"""
function embed_document(embeddings_library,
                        lexicon::Dict{String, Int},
                        doc;
                        embedding_method::Symbol=DEFAULT_EMBEDDING_METHOD)
    # Tokenize
    tokens = extract_tokens(doc)
    # Get word embeddings
    doc_embs, missing_tokens = embed_document(embeddings_library,
                                              tokens,
                                              keep_size=false,
                                              max_compound_word_length=1,
                                              wildcard_matching=true,
                                              print_matched_words=false)
    @debug "Document Embedding: $(tokens[missing_tokens]) could not be embedded."

    ############################################
    # TODO: Language detection wold go here :) #
    ############################################

    # Calculate document embedding
    n = size(embeddings_library)[1]  # number of vector components
    isempty(doc_embs) && return zeros(n)
    em = float(doc_embs)
    embedding_method ==:arora && preprocess_arora_style!(em,
                                    tokens, missing_tokens, lexicon)
    return squash(em)
end



"""
Small function that transforms a document embedding based on word frequencies subtracting the
`paragraph vector` i.e. principal vector from the word embeddings. Useful for transfer learning
i.e. use word embeddings trained in a different context than the one where the matching has to
occur.
[1] "A simple but tough-to-beat baseline for sentence embeddings", Arora et al. ICLR 2017
    (https://openreview.net/pdf?id=SyK00v5xx)
"""
function preprocess_arora_style!(em::Matrix{T},
                                 tokens::Vector{S},
                                 missing_tokens::Vector{Int},
                                 lexicon::Dict{String, Int}) where
            {T<:AbstractFloat, S<:AbstractString}
    # Calculate term frequency vector p
    tt = sum(values(lexicon))
    p = [get(lexicon,tk,eps())/tt for (i, tk) in enumerate(tokens) if !(i in missing_tokens)]
    a = 1
    # There are no sentences, assuming 1-word sentences
    for i in 1:length(p)
        em[:,i] = em[:,i].*(a/(a+p[i]))  # equivalent of vₛ
    end
    u, _, _ = svd(em)
    u = u[:,1]
    for i in 1:length(p)
        em[:,i] -= u'u*em[:,i]
    end
    return em
end



"""
Function that embeds a document i.e. returns an embedding matrix, columns
are word embeddings, using the `word2vec` WordVectors object. The function
has an identical signature as the one from the `ConceptnetNumberbatch`
package.
"""
function embed_document(word_vectors::WordVectors,
                        document_tokens::Vector{S};
                        language=Languages.English(),           # not used
                        keep_size::Bool=true,
                        compound_word_separator::String="_",    # not used
                        max_compound_word_length::Int=1,        # not used
                        wildcard_matching::Bool=false,          # not used
                        print_matched_words::Bool=false,
                       ) where S<:AbstractString
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
    embedding = zeros(n, m)
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
