# Main Embedder type, parametrized by S - typeof string used in the word
# embeddings library, in the arious dictionaries/lexicons and T the type
# of Float of the vectors
abstract type AbstractEmbedder{S<:AbstractString, T<:AbstractFloat}  end


"""
    document2vec(embedder, document [;isregex=false])

Embeds documents. The document representation is conceptually a vector
of sentences, the output is always a vector of floating point numbers.

# Arguments
  * `embedder::AbstractEmbedder` is the embedder
  * `document::Vector{AbstractString}` the document to be embedded,
     where each vector element corresponds to a sentence

# Keyword arguments
  * `isregex::Bool` a `false` value (default) specifies that the
     document tokens are to be matched exactly while a `true` value
     specifies that the tokens are to be matched partially
     (for DTV-based document embedding only)
"""
function document2vec(embedder::AbstractEmbedder, document::Vector{AbstractString}; kwargs...)
    # Prototype of the function only
    throw(ErrorException("`document2vec` is not implemented for the current arguments."))
end


"""
    sentences2vec(embedder, document_embedding, embedded_words [;dim=0])

Returns a matrix of sentence embeddings from a vector of matrices containing
individual sentence word embeddings. Used mostly for word-vectors based
embedders.

# Arguments
  * `embedder::AbstractEmbedder` is the embedder
  * `document_embedding::Vector{Matrix{AbstractFloat}}` are the document's
     word embeddings, where each element of the vector represents the
     embedding of a sentence (whith the matrix columns individual word
     embeddings)

# Keyword arguments
  * `dim::Int` is the dimension of the word embeddings i.e. number of
     components in the word vector (default `0`)
  * `embedded_words::Vector{Vector{AbstractString}}` are the words in
     each sentence the were embedded (their order corresponds to the
     order of the matrix columns in `document_embedding`

"""
function sentences2vec(embedder::AbstractEmbedder,
                       document_embedding::Vector{Matrix{AbstractFloat}};
                       kwargs...)
    # Prototype of the function only
    throw(ErrorException("`sentences2vec` is not implemented for the current arguments."))
end
