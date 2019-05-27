"""
Constant that represents document term vector (DTV) models used in text embedding.
"""
const DTVModel{S,T} = Union{
    StringAnalysis.RPModel{S, T, <:AbstractMatrix{T}, <:Integer},
    StringAnalysis.LSAModel{S, T, <:AbstractMatrix{T}, <:Integer}}


"""
Structure for document embedding using DTV's.
"""
struct DTVEmbedder{S,T} <: AbstractEmbedder{S,T}
    model::DTVModel{S,T}
end


"""
    document2vec(embedder, document [;isregex=false])

DTV-based approach to document embedding. It embeds documents
using simple document term vectors, random projections or latent semantic
(LSA) space projections.

# Arguments
  * `embedder::DTVEmbedder` is the embedder
  * `document::Vector{String}` the document to be embedded,
     where each vector element corresponds to a sentence

# Keyword arguments
  * `isregex::Bool` a `false` value (default) specifies that the
     document tokens are to be matched exactly while a `true` value
     specifies that the tokens are to be matched partially
"""
function document2vec(embedder::DTVEmbedder{S,T},
                      document::Vector{String};  # a vector of sentences
                      isregex::Bool=false,
                      kwargs...  # for the unused arguments
                     )::SparseVector{T, Int} where {S,T}
    dtv_function = ifelse(isregex, dtv_regex, dtv)
    words = Vector{String}()
    for sentence in document
        for word in tokenize(sentence, method=:fast)
            push!(words, word)
        end
    end
    vocab_hash = embedder.model.vocab_hash
    model = embedder.model
    v = dtv_function(words, vocab_hash, T,
                     tokenizer=DEFAULT_TOKENIZER,
                     lex_is_row_indices=true)
    embedded_document = embed_document(model, v)
    return embedded_document
end
