"""
Constant that represents document term vector (DTV) models used in text embedding.
"""
const DTVModel{T,S} = Union{
    StringAnalysis.RPModel{S,T,<:AbstractMatrix{T},<:Integer},
    StringAnalysis.LSAModel{S,T,<:AbstractMatrix{T},<:Integer}
}


"""
Structure for document embedding using DTV's.
"""
struct DTVEmbedder{T,S} <: AbstractEmbedder{T,S}
    model::DTVModel{T,S}
    config::NamedTuple
end

DTVEmbedder(mtype::Type{<:DTVModel}, dtm, config; kwargs...) = DTVEmbedder(mtype(dtm; kwargs...), config)


# Document to vector embedding function
function __document2vec(embedder::DTVEmbedder{T,S},
                        document::Vector{String};  # a vector of sentences
                        isregex::Bool=false,
                        kwargs...  # for the unused arguments
                       )::SparseVector{T, Int} where {T,S}
    dtv_function = ifelse(isregex, dtv_regex, dtv)
    words = Vector{String}()
    for sentence in document
        for word in tokenize(sentence, method=:stringanalysis)
            push!(words, word)
        end
    end
    vocab_hash = embedder.model.vocab_hash
    model = embedder.model
    v = dtv_function(words, vocab_hash, T;
                     ngram_complexity=embedder.config.ngram_complexity,
                     tokenizer=DEFAULT_TOKENIZER,
                     lex_is_row_indices=true)
    embedded_document = StringAnalysis.embed_document(model, v)
    return embedded_document
end

function document2vec(embedder::DTVEmbedder{T,S},
                      document::Vector{String};  # a vector of sentences
                      isregex::Bool=false,
                      kwargs...  # for the unused arguments
                     )::Tuple{SparseVector{T, Int}, Bool} where {T,S}
    embedded_document = __document2vec(embedder,
                                       document;
                                       isregex=isregex,
                                       kwargs...)
    is_embedded = !iszero(embedded_document)
    # Check for OOV (out-of-vocabulary) policy
    if embedder.config.oov_policy == :large_vector && !is_embedded
        embedded_document .= T(DEFAULT_OOV_VAL)
    end
    return embedded_document, is_embedded
end


# Dimensionality function
function dimensionality(embedder::DTVEmbedder)
    # Return output dimensionality (second dim)
    return size(embedder.model)[2]
end
