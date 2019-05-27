const DTVModel{S,T} = Union{
    StringAnalysis.RPModel{S, T, <:AbstractMatrix{T}, <:Integer},
    StringAnalysis.LSAModel{S, T, <:AbstractMatrix{T}, <:Integer}}


struct DTVEmbedder{S,T} <: AbstractEmbedder{S,T}
    model::DTVModel{S,T}
end


# Classic approach to document embedding: simple document term vectors,
# random projections or LSA space projection
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
