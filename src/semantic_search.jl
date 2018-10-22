#TODO(Corneliu) EmbeddedDocument Interface
#   - EmbeddedDocument <:AbstractDocument
#   - two fiedls: metadata and embeddings (a single vector of numbers)
#   - constructor: EmbeddedDocument(<:ConceptNet, (string/tokens/ngrams), embedding_method::Symbol
#   - methods to convert any existing AbstractDocument to EmbeddedDocument
#   - A corpus of N embedded documents can be dumped as a vector of metadata and a matrix N×m (m - embedding dim)
#   - Semantic search in this case would embed the query (using embedding_method)
#     and multiply it by the matrix: N×m⋅m×1 --> a vector N×1 which after sorting represents the matches
# ------------------------------------------------------------------------------------------------------------
#
# Things to investigate here:
#  - methods to construct the embedding for a Document
#  - methods to get as many words as possible given the fact that mispellings may occur
#  - what words can be safely removed from document/metadata/query without losing match quality
#  - performance increases through dimensionality reduction and using SparseArrays with vector component
#    clamping and renormalization


# Searcher structures
mutable struct SemanticCorpusSearcher{T<:AbstractId,
                                      D<:AbstractDocument,
                                      U<:AbstractVector} <: AbstractSearcher
    id::T
    enabled::Bool
    ref::CorpusRef{T}
    embeddings::Dict{Symbol, Vector{U}}
end

show(io::IO, semantic_corpus_searcher::SemanticCorpusSearcher{T,D,U}) where
        {T<:AbstractId, D<:AbstractDocument, U<:AbstractVector} = begin
    printstyled(io, "SemanticCorpusSearcher{$T,$D,$U}, ")
    printstyled(io, "[$(semantic_corpus_searcher.id)] ", color=:cyan)
    _status = ifelse(semantic_corpus_searcher.enabled, "Enabled", "Disabled")
    _status_color = ifelse(semantic_corpus_searcher.enabled, :light_green, :light_black)
    printstyled(io, "[$_status] ", color=_status_color)
    printstyled(io, "$(semantic_corpus_searcher.ref.name)", color=:normal)
    printstyled(io, ", $(length(semantic_corpus_searcher.corpus)) documents\n")
end


mutable struct SemanticCorporaSearcher{T,D,U,
        V<:AbstractVector{SemanticCorpusSearcher{T,D,U}}} <: AbstractSearcher
    searchers::V
    idmap::Dict{T, Int}
end


show(io::IO, semantic_corpora_searcher::SemanticCorporaSearcher) = begin
    printstyled(io, "$(length(semantic_corpora_searcher.searchers))"*
                "-element SemanticCorporaSearcher:\n")
    for (id, idx) in semantic_corpora_searcher.idmap
        print(io, "`-", semantic_corpora_searcher.searchers[idx])
    end
end



# Function to create a semantic search structure from corpus refs' similar to corpora_searchers
function semantic_corpora_searchers(filename::AbstractString)
    crefs = parse_corpora_configuration(filename)
    cptnet = load_embeddings("../_conceptnet/mini.h5",
                             languages=[Languages.English()])
    semantic_corpora_searchers(crefs, cptnet)
end

function semantic_corpora_searchers(crefs::Vector{CorpusRef{T}},
                                    cptnet::ConceptNet{L,K,U};
                                    doc_type::Type{D}=DEFAULT_DOC_TYPE) where
        {T<:AbstractId, D<:AbstractDocument, L<:Languages.Language,
         K<:AbstractString, U<:AbstractVector}
    n = length(crefs)
    semantic_corpora_searcher = SemanticCorporaSearcher(
        Vector{SemanticCorpusSearcher{T,D,U}}(), Dict{T,Int}())
    for (i, cref) in enumerate(crefs)
        add_semantic_searcher!(semantic_corpora_searcher, cref, cptnet, i)
    end
	return corpora_searcher
end


function get_document_embedding(cptnet::ConceptNet{L,K,U}, doc::NGramDocument) where
        {L<:Languages.Language, K<:AbstractString, U<:AbstractVector}
    # Function to get from multiple word-embeddings to a document embedding
    function squash_embeddings(embs::Matrix)
        tmp = vec(mean(embs,2))
    end
    doc_embs = embed_document(cptnet,
                              collect(keys(doc.ngrams)),
                              keep_size=false,
                              max_compound_word_length=1,
                              search_mismatches=:no,
                              show_words=false)
    # Return embeddings
    embedding = squash_embeddings(doc_embs)
    return embedding
end

function add_semantic_searcher!(semantic_corpora_searcher, cref,
                                cptnet::ConceptNet{L,K,U}, index::Int) where
        {L<:Languages.Language, K<:AbstractString, U<:AbstractVector}
    # Parse file
    crps, crps_meta = cref.parser(cref.path)
    # get id
    id = cref.id
    # Prepare
    prepare!(crps, TEXT_STRIP_FLAGS)
    prepare!(crps_meta, METADATA_STRIP_FLAGS)
    ### # Update lexicons
    ### update_lexicon!(crps)
    ### update_lexicon!(crps_meta)
    ### # Update inverse indices
    ### update_inverse_index!(crps)
    ### update_inverse_index!(crps_meta)
    
    _scs = SemanticCorpusSearcher(id,
                                  cref.enabled,
                                  cref,
                                  Dict{Symbol, Vector{U}}()
                                 )
    # Update CorpusSearcher
    push!(_scs.embeddings, :index=>[get_document_embedding(cptnet, doc)
                                    for doc in crps])
    push!(_scs.embeddings, :metadata=>[get_document_embedding(cptnet, doc)
                                       for doc in crps_meta])
end


# Function that searches a query through the semantic search structures
function search(semantic_crpra_searcher::SemanticCorporaSearcher{T,D,V},
                query::AbstractString;
                search_type::Symbol=DEFAULT_SEARCH_TYPE,
                max_matches::Int=DEFAULT_MAX_MATCHES) where
        {T<:AbstractId, D<:AbstractDocument, V<:AbstractVector}
    # Checks
    @assert search_type in [:index, :metadata, :all]
    @assert max_matches >= 0
    # Initializations
    n = length(semantic_crpra_searcher.searchers)
    max_corpus_suggestions = min(max_suggestions, max_corpus_suggestions)
    # Search
    result_vector = [SemanticCorpusSearchResult() for _ in 1:n]
    id_vector = [random_id(T) for _ in 1:n]
    @threads for i in 1:n
        if semantic_crpra_searcher.searchers[i].enabled
            # Get corpus search results
            id, search_result = search(semantic_crpra_searcher.searchers[i],
                                       query,
                                       cptnet,
                                       search_type=search_type,
                                       max_matches=max_matches)
            result_vector[i] = search_result
            id_vector[i] = id
        end
    end
    # Add corpus search results to the corpora search results
    result = CorporaSearchResult{T}()
    for i in 1:n
        if semantic_crpra_searcher.searchers[i].enabled
            push!(result, id_vector[i]=>result_vector[i])
        end
    end
    return result
end

function search(semantic_crps_searcher::SemanticCorpusSearcher{T,D},
                query::AbstractString,
                search_type::Symbol=:metadata,
                max_matches::Int=10,
               ) where {T<:AbstractId, D<:AbstractDocument}
    # Initializations
    n = length(semantic_crps_searcher.corpus)    # number of documents
    # Search metadata and/or index
    where_to_search = ifelse(search_type==:all,
                             [:index, :metadata],
                             [search_type])
    document_scores = zeros(Float64, n)     # document relevance
    _query = get_document_embedding(cptnet, query)
    for wts in where_to_search
        # search
        document_scores += search(_query, semantic_crps_searcher.embeddings[wts])
    end
    # Process documents found (sort by score)
    documents_ordered::Vector{Tuple{Float64, Int}} =
        [(score, i) for (i, score) in enumerate(document_scores) if score > 0]
    sort!(documents_ordered, by=x->x[1], rev=true)
    query_matches = MultiDict{Float64, Int}()
    @inbounds for i in 1:min(max_matches, length(documents_ordered))
        push!(query_matches, document_scores[documents_ordered[i][2]]=>
                             documents_ordered[i][2])
    end
    # Get suggestions
    suggestions = MultiDict{String, Tuple{Float64, String}}()
    needle_matches = Dict{String, Float64}()
    return semantic_crps_searcher.id, CorpusSearchResult(query_matches, needle_matches, suggestions)
end


function search(query, embeddings)
    n = length(embeddings)
    similarity = Vector{Float64}(undef, n)
    for (i, doc_embedding) in embeddings
        similarity[i] = query'*doc_embedding
    end
    return similarity
end
