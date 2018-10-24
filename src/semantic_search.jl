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
                                      D<:AbstractDocument} <: AbstractSearcher
    id::T
    corpus::Corpus{D}
    enabled::Bool
    ref::CorpusRef{T}
    embeddings::Dict{Symbol, Matrix{Float64}}
end

show(io::IO, semantic_corpus_searcher::SemanticCorpusSearcher{T,D}) where
        {T<:AbstractId, D<:AbstractDocument} = begin
    printstyled(io, "$(typeof(semantic_corpus_searcher)), ")
    printstyled(io, "[$(semantic_corpus_searcher.id)] ", color=:cyan)
    _status = ifelse(semantic_corpus_searcher.enabled, "Enabled", "Disabled")
    _status_color = ifelse(semantic_corpus_searcher.enabled, :light_green, :light_black)
    printstyled(io, "[$_status] ", color=_status_color)
    printstyled(io, "$(semantic_corpus_searcher.ref.name)", color=:normal)
    printstyled(io, ", $(length(semantic_corpus_searcher.corpus)) documents\n")
end


mutable struct SemanticCorporaSearcher{T,D}
    searchers::Vector{SemanticCorpusSearcher{T,D}}
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
function semantic_corpora_searchers(filename::AbstractString,
                                    cptnetpath::AbstractString;
                                    languages=[Languages.English()])
    crefs = parse_corpora_configuration(filename)
    cptnet = ConceptnetNumberbatch.load_embeddings(cptnetpath, languages=languages)
    semantic_corpora_searchers(crefs, cptnet)
end

function semantic_corpora_searchers(crefs::Vector{CorpusRef{T}},
                                    conceptnet::ConceptNet{L,K,U};
                                    doc_type::Type{D}=DEFAULT_DOC_TYPE) where
        {T<:AbstractId, D<:AbstractDocument, L<:Languages.Language,
         K<:AbstractString, U<:AbstractVector}
    n = length(crefs)
    semantic_corpora_searcher = SemanticCorporaSearcher(
        Vector{SemanticCorpusSearcher{T,D}}(undef, n), Dict{T,Int}())
    for (i, cref) in enumerate(crefs)
        semantic_corpora_searcher.searchers[i] = semantic_corpus_searcher(cref, conceptnet)
        push!(semantic_corpora_searcher.idmap, cref.id=>i)
    end
	return semantic_corpora_searcher
end


# Function to get from multiple word-embeddings to a document embedding
function get_document_embedding(conceptnet::ConceptNet{L,K,U}, doc) where
        {L<:Languages.Language, K<:AbstractString, U<:AbstractVector}
    # Text extraction methods various types of documents
    extract_text(doc::NGramDocument) = collect(keys(doc.ngrams))
    extract_text(doc::StringDocument) = doc.text
    extract_text(doc::AbstractString) = doc

    doc_embs, _ = embed_document(conceptnet,
                                 extract_text(doc),
                                 keep_size=false,
                                 max_compound_word_length=2,
                                 wildcard_matching=true,
                                 print_matched_words=false)

    # TODO: Language detection wold go here :)

    # Return a single document vector
    if isempty(doc_embs)
        return zeros(size(conceptnet))
    else 
        return squash_embeddings(float(doc_embs))
    end 
end

function squash_embeddings(embs::V) where V<:AbstractArray{<:Real}
    # Calculate document embedding
    ##############################
    #@inbounds @simd for i in 1:size(embs,2)
    #    col = view(embs, :, i)
    #    embs[:,i] = col./(norm(col,1)+eps())
    #end
    v = vec(mean(embs, dims=2))
    return v./(norm(v,1)+eps())
end


function semantic_corpus_searcher(cref, conceptnet::ConceptNet{L,K,U}) where
        {L<:Languages.Language, K<:AbstractString, U<:AbstractVector}
    # Parse file
    crps, crps_meta = cref.parser(cref.path)
    # Prepare
    prepare!(crps, TEXT_STRIP_FLAGS)
    prepare!(crps_meta, METADATA_STRIP_FLAGS)
    ### # Update lexicons
    ### update_lexicon!(crps)
    ### update_lexicon!(crps_meta)
    ### # Update inverse indices
    ### update_inverse_index!(crps)
    ### update_inverse_index!(crps_meta)

    scs = SemanticCorpusSearcher(cref.id,
                                 crps,
                                 cref.enabled,
                                 cref,
                                 Dict{Symbol, Matrix{Float64}}())
    # Update CorpusSearcher
    push!(scs.embeddings, :index=>hcat((get_document_embedding(conceptnet, doc)
                                        for doc in crps)...))
    push!(scs.embeddings, :metadata=>hcat((get_document_embedding(conceptnet, doc)
                                           for doc in crps_meta)...))
    return scs
end


# Function that searches a query through the semantic search structures
function search(semantic_crpra_searcher::SemanticCorporaSearcher{T,D},
                conceptnet::ConceptNet{L,K,U},
                query::AbstractString;
                search_type::Symbol=DEFAULT_SEARCH_TYPE,
                max_matches::Int=DEFAULT_MAX_MATCHES
                ) where
        {T<:AbstractId, D<:AbstractDocument, U<:AbstractVector,
         L<:Languages.Language, K<:AbstractString}
    # Checks
    @assert search_type in [:index, :metadata, :all]
    @assert max_matches >= 0
    # Initializations
    n = length(semantic_crpra_searcher.searchers)
    result_vector = [CorpusSearchResult() for _ in 1:n]
    id_vector = [random_id(T) for _ in 1:n]
    for i in 1:n
        if semantic_crpra_searcher.searchers[i].enabled
            # Get corpus search results
            id, search_result = search(semantic_crpra_searcher.searchers[i],
                                       conceptnet,
                                       query,
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
                conceptnet::ConceptNet{L,K,U},
                query::AbstractString;
                search_type::Symbol=:metadata,
                max_matches::Int=10) where
        {T<:AbstractId, D<:AbstractDocument, U<:AbstractVector,
         L<:Languages.Language, K<:AbstractString}
    # Initializations
    n = length(semantic_crps_searcher.corpus)    # number of documents
    # Search metadata and/or index
    where_to_search = ifelse(search_type==:all,
                             [:index, :metadata],
                             [search_type])
    document_scores = zeros(Float64, n)     # document relevance
    _query = get_document_embedding(conceptnet, query)
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

function search(query::Vector{N}, embeddings::Matrix{N}) where N<:AbstractFloat
    embeddings'*query
end



# Pretty printer of results
print_search_results(crpra_searcher::SemanticCorporaSearcher, csr::CorporaSearchResult) = begin
    if !isempty(csr.corpus_results)
        nt = mapreduce(x->valength(x[2].query_matches), +, csr.corpus_results)
    else
        nt = 0
    end
    printstyled("$nt semantic search results from $(length(csr.corpus_results)) corpora\n")
    ns = length(csr.suggestions)
    for (id, _result) in csr.corpus_results
        crps = crpra_searcher.searchers[crpra_searcher.idmap[id]].corpus
        nm = valength(_result.query_matches)
        printstyled("`-[$id] ", color=:cyan)  # hash
        printstyled("$(nm) search results")
        ch = ifelse(nm==0, ".", ":"); printstyled("$ch\n")
        for score in sort(collect(keys(_result.query_matches)), rev=true)
            for doc in (crps[i] for i in _result.query_matches[score])
                printstyled("  $score ~ ", color=:normal, bold=true)
                printstyled("$(metadata(doc))\n", color=:normal)
            end
        end
    end
    ns > 0 && printstyled("$ns suggestions:\n")
    for (keyword, suggestions) in csr.suggestions
        printstyled("  \"$keyword\": ", color=:normal, bold=true)
        printstyled("$(join(suggestions, ", "))\n", color=:normal)
    end
end
