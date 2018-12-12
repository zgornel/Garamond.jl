##################
# Search methods #
##################

"""
	search(srcher, query [;kwargs])

Searches for query (i.e. key terms) in multiple corpora and returns
information regarding the documents that match best the query.
The function returns the search results in the form of
a `Vector{SearchResult}`.

# Arguments
  * `srcher::AbstractVector{AbstractSearcher}` is the corpora searcher
  * `query` the query

# Keyword arguments
  * `search_type::Symbol` is the type of the search; can be `:metadata`,
     `:data` or `:all`; the options specify that the query can be found in
     the metadata of the documents of the corpus, the document content or both
     respectively
  * `search_method::Symbol` controls the type of matching: `:exact`
     searches for the very same string while `:regex` searches for a string
     in the corpus that includes the needle
  * `max_matches::Int` is the maximum number of search results to return from
     each corpus
  * `max_corpus_suggestions::Int` is the maximum number of suggestions to return for
     each missing needle from the search in a corpus
"""
function search(srchers::V,
                query;
                search_type::Symbol=DEFAULT_SEARCH_TYPE,
                search_method::Symbol=DEFAULT_SEARCH_METHOD,
                max_matches::Int=MAX_MATCHES,
                max_corpus_suggestions::Int=MAX_CORPUS_SUGGESTIONS) where
        {V<:Vector{<:Searcher{D,E,M} where D<:AbstractDocument
                   where E where M<:AbstractSearchData}}
    # Checks
    @assert search_type in [:data, :metadata, :all]
    @assert search_method in [:exact, :regex]
    @assert max_matches >= 0
    @assert max_corpus_suggestions >=0
    # Initializations
    n = length(srchers)
    enabled_searchers = [i for i in 1:n if isenabled(srchers[i])]
    n_enabled = length(enabled_searchers)
    queries = [prepare_query(query, srcher.config.query_strip_flags)
               for srcher in srchers]
    # Search
    results = Vector{SearchResult}(undef, n_enabled)
    ###################################################################
    # A `Threads.@threads` statement in front of the for loop here
    # idicates the use of multi-threading. If multi-threading is used,
    # OPENBLAS multi-threading support has to be disabled by using:
    #   `export OPENBLAS_NUM_THREADS=1` in the shell
    # or start julia with:
    #   `env OPENBLAS_NUM_THREADS=1 julia`
    #
    # WARNING: Multi-theading support (as of v1.1 is still EXPERIMENTAL)
    #          and floating point operations are not thread-safe!
    #          Do not use with semantic search!!
    ###################################################################
    ### Threads.@threads for i in 1:n_enabled
    for i in 1:n_enabled
        # Get corpus search results
        results[i] = search(srchers[enabled_searchers[i]],
                            queries[enabled_searchers[i]],
                            search_type=search_type,
                            search_method=search_method,
                            max_matches=max_matches,
                            max_suggestions=max_corpus_suggestions)
    end
    # Return vector of tuples, each tuple containing the id and search results
    return results::Vector{SearchResult}  # not necessary without `@threads`
end



"""
	search(srcher, query [;kwargs])

Searches for query (i.e. key terms) in a corpus' metadata, text or both and
returns information regarding the the documents that match best the query.
The function returns an object of type SearchResult and the id of the searcher.

# Arguments
  * `srcher::Searcher` is the corpus searcher
  * `query` the query

# Keyword arguments
  * `search_type::Symbol` is the type of the search; can be `:metadata`,
     `:data` or `:all`; the options specify that the query can be found in
     the metadata of the documents of the corpus, the document content or both
     respectively
  * `search_method::Symbol` controls the type of matching: `:exact`
     searches for the very same string while `:regex` searches for a string
     in the corpus that includes the needle
  * `max_matches::Int` is the maximum number of search results to return
  * `max_suggestions::Int` is the maximum number of suggestions to return for
     each missing needle
"""
# Function that searches in a corpus'a metdata or
# metadata + content for query (i.e. keyterms)
function search(srcher::Searcher{D,E,M},
                query;
                search_type::Symbol=:metadata,
                search_method::Symbol=:exact,
                max_matches::Int=10,
                max_suggestions::Int=MAX_CORPUS_SUGGESTIONS) where
        {D<:AbstractDocument, E, M<:AbstractDocumentCount}
    # Tokenize
    needles = prepare_query(query, srcher.config.query_strip_flags)
    # Initializations
    n = length(srcher.search_data[:data])    # number of documents
    p = length(needles)                 # number of search terms
    # Search metadata and/or data
    where_to_search = ifelse(search_type==:all,
                             [:data, :metadata],
                             [search_type])
    document_scores = zeros(DEFAULT_COUNT_ELEMENT_TYPE, n)     # document relevance
    needle_popularity = zeros(DEFAULT_COUNT_ELEMENT_TYPE, p)   # needle relevance
    for wts in where_to_search
        # search
        inds = search(srcher.search_data[wts], needles, method=search_method)
        # select term importance vectors
        _M = view(srcher.search_data[wts].values, :, inds)
        @inbounds @simd for j in 1:p
             for i in 1:n
                if _M[i,j] != 0.0
                    document_scores[i]+= _M[i,j]
                    needle_popularity[j]+= _M[i,j]
                end
            end
        end
    end
    # Process documents found (sort by score)
    documents_ordered::Vector{Tuple{DEFAULT_COUNT_ELEMENT_TYPE, Int}} =
        [(score, i) for (i, score) in enumerate(document_scores) if score > 0]
    sort!(documents_ordered, by=x->x[1], rev=true)
    query_matches = MultiDict{DEFAULT_COUNT_ELEMENT_TYPE, Int}()
    @inbounds for i in 1:min(max_matches, length(documents_ordered))
        push!(query_matches, document_scores[documents_ordered[i][2]]=>
                             documents_ordered[i][2])
    end
    # Process needles (search heuristically for missing ones,
    # construct various SearchResult structures)
    needle_matches = Dict(needle=>needle_popularity[i]
                          for (i, needle) in enumerate(needles)
                          if needle_popularity[i] > 0)
    # Get suggestions
    suggestions = MultiDict{String, Tuple{DEFAULT_COUNT_ELEMENT_TYPE, String}}()
    missing_needles = map(iszero, needle_popularity)
    if max_suggestions > 0 && any(missing_needles)
        needles_not_found = needles[missing_needles]
        where_to_search = ifelse(search_type == :all,
                                 [:data, :metadata],
                                 [search_type])
        # Get suggestions
        for wts in where_to_search
            search_heuristically!(suggestions,
                                  srcher.search_trees[wts],
                                  needles_not_found,
                                  max_suggestions=max_suggestions)
        end
    end
    return SearchResult(id(srcher), query_matches, needle_matches, suggestions)
end


"""
    search(termcnt, needles, method)

Search function for searching using the term imporatances associated to a corpus.
"""
function search(termcnt::TermCounts, needles::Vector{S}; method::Symbol=:exact
               ) where S<:AbstractString
    # Initializations
    p = length(needles)
    I = termcnt.column_indices
    V = termcnt.values
    m, n = size(termcnt.values)  # m - no. of documents, n - no. of terms+1
    inds = fill(n,p)  # default value n i.e. return 0-vector from V
    # Get needle mutating and string matching functions
    if method == :exact
        needle_mutator = identity
        matching_function = isequal
    else  # method == :regex
        needle_mutator = (arg::S)->Regex(arg)
        matching_function = occursin
    end
    # Mutate needles
    patterns = needle_mutator.(needles)
    # Search
    haystack = keys(I)
    empty_vector = Int[]
    if method == :exact
        for (j, pattern) in enumerate(patterns)
            inds[j] = get(I, pattern, n)
        end
    else  # method==:regex
        for (j, pattern) in enumerate(patterns)
            for k in haystack
                if matching_function(pattern, k)
                    inds[j] = get(I, k, n)
                end
            end
        end
    end
    return inds
end


"""
    search_heuristically!(suggestions, search_tree, needles [;max_suggestions=1])

Searches in the search tree for partial matches of the `needles`.
"""
function search_heuristically!(suggestions::MultiDict{String,
                                    Tuple{DEFAULT_COUNT_ELEMENT_TYPE, String}},
                               search_tree::BKTree{String},
                               needles::Vector{S};
                               max_suggestions::Int=1) where S<:AbstractString
    if isempty(needles)
        return suggestions
    else  # there are terms that have not been found
        # Checks
        @assert !BKTrees.is_empty_node(search_tree.root) "FATAL: empty search tree."
        for needle in needles
            _suggestions = sort!(find(search_tree, String(needle),
                                      MAX_EDIT_DISTANCE,
                                      k=max_suggestions),
                                 by=x->x[1])
            if !isempty(_suggestions)
                n = min(max_suggestions, length(_suggestions))
                push!(suggestions, needle=>_suggestions[1:n])
            end
        end
    end
    return suggestions
end



"""
    get_embedding_eltype(embeddings)

Function that returns the type of the embeddings' elements. The type is useful to
generate score vectors. If the element type is and `Int8` (ConceptNet compressed),
the returned type is the DEFAULT_EMBEDDING_TYPE.
"""
# Get embedding element types
get_embedding_eltype(::Word2Vec.WordVectors{S,T,H}) where
    {S<:AbstractString, T<:Real, H<:Integer} = T
get_embedding_eltype(::Glowe.WordVectors{S,T,H}) where
    {S<:AbstractString, T<:Real, H<:Integer} = T
get_embedding_eltype(::ConceptNet{L,K,E}) where
    {L<:Language, K<:AbstractString, E<:AbstractFloat} = E
get_embedding_eltype(::ConceptNet{L,K,E}) where
    {L<:Language, K<:AbstractString, E<:Integer} = DEFAULT_EMBEDDING_ELEMENT_TYPE



# Semantic search method (M<:AbstractEmbeddingModel)
function search(srcher::Searcher{D,E,M},
                query;  # can be either a string or vector of strings
                search_type::Symbol=:metadata,
                search_method::Symbol=Symbol(),  #not used
                max_matches::Int=10,
                max_suggestions::Int=MAX_CORPUS_SUGGESTIONS  # not used
                ) where
        {D<:AbstractDocument, E, M<:AbstractEmbeddingModel}
    # Tokenize
    needles = prepare_query(query, srcher.config.query_strip_flags)
    # Initializations
    n = length(srcher.search_data[:data])  # number of embedded documents
    # Search metadata and/or data
    where_to_search = ifelse(search_type==:all,
                             [:data, :metadata],
                             [search_type])
    # Embed query
    query_embedding = embed_document(srcher.embeddings,
                        srcher.corpus.lexicon,
                        needles,
                        embedding_method=srcher.config.embedding_method)
    idxs = Int[]
    score_type = get_embedding_eltype(srcher.embeddings)
    scores = score_type[]
    k = min(n, max_matches)
    for wts in where_to_search
        # search
        _idxs, _scores = search(srcher.search_data[wts], query_embedding, k)
        push!(idxs, _idxs...)
        push!(scores, _scores...)
        if search_type == :all
            idxs, scores = _merge_indices_and_scores(idxs, scores, k)
        end
    end
    # Process documents found (sort by score)
    query_matches = MultiDict(zip(scores, idxs))
    # Get suggestions
    suggestions = MultiDict{String, Tuple{score_type, String}}()
    needle_matches = Dict{String, score_type}()
    return SearchResult(id(srcher), query_matches, needle_matches, suggestions)
end



# Small function that processes two vectors a and b where
# a is assumed to be a vector of document idices (with possible
# duplicates and b the corresponding scores)
function _merge_indices_and_scores(idxs, scores, k)
    seen = Dict{Int,Int}()  # idx=>i
    removable = Int[]
    for (i, idx) in enumerate(idxs)
        if !(idx in keys(seen))
            push!(seen, idx=>i)
        else
            # Already seen (duplicate)
            scores[[i, seen[idx]]] .= (scores[i] + scores[seen[idx]])/2
            push!(removable, i)
        end
    end
    deleteat!(idxs, removable)
    deleteat!(scores, removable)
    # Precaution for HSNW which may not return
    # an *exact* number of neighbors
    k = min(k, length(idxs))
    # Sort, take first k neighbors and return
    order = sortperm(scores)[1:k]
    return idxs[order], scores[order]
end
