# Text extraction methods various types of documents
extract_tokens(doc::NGramDocument) = collect(keys(doc.ngrams))
extract_tokens(doc::StringDocument) = tokenize_for_conceptnet(doc.text)
extract_tokens(doc::AbstractString) = tokenize_for_conceptnet(doc)



# Function that creates a single mean vector from a vector or matrix
squash(m) = begin
    # Calculate document embedding
    ##############################
    v = vec(mean(m, dims=2))
    return v./(norm(v,2)+eps())
end


# TODO(Corneliu) Make an embed_document function for Word2Vec

# Function to get from multiple word-embeddings to a document embedding
# Through the embedding method, the algorithm for combining multiple word wmbeddings
# into a single document embedding is controlled. Avalilable options:
#   :bow - calculate document embedding as the mean of the word embeddings
#   :arora - algorithm from [1] "A simple but tough-to-beat baseline for sentence embeddings",
#           Arora et al. ICLR 2017 (https://openreview.net/pdf?id=SyK00v5xx)
#           [not working properly unless full documents are used]
function get_document_embedding(conceptnet::ConceptNet, lexicon, doc;
                                embedding_method::Symbol=DEFAULT_EMBEDDING_METHOD)
    # Tokenize
    tokens = extract_tokens(doc)
    # Get word embeddings
    doc_embs, missing_tokens = embed_document(conceptnet,
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
    n = size(conceptnet,1)
    isempty(doc_embs) && return zeros(n)
    em = float(doc_embs)
    if embedding_method ==:arora
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
    end
    return squash(em)
end

function get_document_embedding(word_vectors::WordVectors, lexicon, doc;
                                embedding_method::Symbol=DEFAULT_EMBEDDING_METHOD)
    @warn "Word2Vec document embedding not supported, return zero vector..."
    # TODO(Corneliu) Implement
    return zeros(size(word_vectors.vectors, 1))
end
