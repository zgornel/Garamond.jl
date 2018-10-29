##################
# Search methods #
##################

"""
	search(searcher, query [;kwargs])

Searches for query (i.e. key terms) in a multiple corpora and returns
information regarding the documents that match best the query.
The function returns an object of type AggregateSearchResult.

# Arguments
  * `searcher::AggregateSearcher{T,D}` is the corpora searcher
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
  * `max_suggestions::Int` is the maximum number of suggestions to return for
     each missing needle for all searched corpora
  * `max_corpus_suggestions::Int` is the maximum number of suggestions to return for
     each missing needle from the search in a corpus

# Examples
```
	...
```
"""
function search(searcher::AggregateSearcher{T,S},
                query;
                search_type::Symbol=DEFAULT_SEARCH_TYPE,
                search_method::Symbol=DEFAULT_SEARCH_METHOD,
                max_matches::Int=DEFAULT_MAX_MATCHES,
                max_suggestions::Int=DEFAULT_MAX_SUGGESTIONS,
                max_corpus_suggestions::Int=DEFAULT_MAX_CORPUS_SUGGESTIONS) where
        {T<:AbstractId, S<:AbstractSearcher}
    # Checks
    # TODO(Corneliu) Adapt checks and options to individual searcher types
    @assert search_type in [:data, :metadata, :all]
    @assert search_method in [:exact, :regex]
    @assert max_matches >= 0
    @assert max_suggestions >= 0
    @assert max_corpus_suggestions >=0
    # Initializations
    n = length(searcher.searchers)
    max_corpus_suggestions = min(max_suggestions, max_corpus_suggestions)
    # Search
    result_vector = [SearchResult() for _ in 1:n]
    id_vector = [random_id(T) for _ in 1:n]
    @threads for i in 1:n
        if searcher.searchers[i].enabled
            # Get corpus search results
            id, search_result = search(searcher.searchers[i],
                                       query,
                                       search_type=search_type,
                                       search_method=search_method,
                                       max_matches=max_matches,
                                       max_suggestions=max_corpus_suggestions)
            result_vector[i] = search_result
            id_vector[i] = id
        end
    end
    # Add corpus search results to the corpora search results
    result = AggregateSearchResult{T}()
    for i in 1:n
        if searcher.searchers[i].enabled
            push!(result, id_vector[i]=>result_vector[i])
        end
    end
    squash_suggestions!(result, max_suggestions)
    return result
end



##################
# Classic search #
##################
"""
	search(searcher, query [;kwargs])

Searches for query (i.e. key terms) in a corpus' metadata, text or both and 
returns information regarding the the documents that match best the query.
The function returns an object of type SearchResult and the id of the
ClassicSearcher.

# Arguments
  * `searcher::ClassicSearcher{T,D}` is the corpus searcher
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

# Examples
```
	...
```
"""
# Function that searches in a corpus'a metdata or metadata + content for query (i.e. keyterms) 
function search(searcher::ClassicSearcher{T,D},
                query;
                search_type::Symbol=:metadata,
                search_method::Symbol=:exact,
                max_matches::Int=10,
                max_suggestions::Int=DEFAULT_MAX_CORPUS_SUGGESTIONS
               ) where {T<:AbstractId, D<:AbstractDocument}
    # Tokenize
    needles = extract_tokens(query)
    # Initializations
    n = size(searcher.term_counts[:data].values, 1)    # number of documents
    p = length(needles)                 # number of search terms
    # Search metadata and/or data
    where_to_search = ifelse(search_type==:all,
                             [:data, :metadata],
                             [search_type])
    document_scores = zeros(Float64, n)     # document relevance
    needle_popularity = zeros(Float64, p)   # needle relevance
    for wts in where_to_search
        # search
        inds = search(needles, searcher.term_counts[wts], search_method=search_method)
        # select term importance vectors
        M = view(searcher.term_counts[wts].values, :, inds)
        @inbounds @simd for j in 1:p
             for i in 1:n
                if M[i,j] != 0.0
                    document_scores[i]+= M[i,j]
                    needle_popularity[j]+= M[i,j]
                end
            end
        end
    end
    # Process documents found (sort by score)
    documents_ordered::Vector{Tuple{Float64, Int}} =
        [(score, i) for (i, score) in enumerate(document_scores) if score > 0]
    sort!(documents_ordered, by=x->x[1], rev=true)
    needles_matches = MultiDict{Float64, Int}()
    @inbounds for i in 1:min(max_matches, length(documents_ordered))
        push!(needles_matches, document_scores[documents_ordered[i][2]]=>
                             documents_ordered[i][2])
    end
    # Process needles (search heuristically for missing ones,
    # construct various SearchResult structures)
    needle_matches = Dict(needle=>needle_popularity[i]
                          for (i, needle) in enumerate(needles)
                          if needle_popularity[i] > 0)
    # Get suggestions
    suggestions = MultiDict{String, Tuple{Float64, String}}()
    missing_needles = map(iszero, needle_popularity)
    if max_suggestions > 0 && any(missing_needles)
        needles_not_found = needles[missing_needles]
        where_to_search = ifelse(search_type == :all,
                                 [:data, :metadata],
                                 [search_type])
        # Get suggestions
        for wts in where_to_search
            search_heuristically!(suggestions,
                                  searcher.search_trees[wts],
                                  needles_not_found,
                                  max_suggestions=max_suggestions)
        end
    end
    return searcher.id, SearchResult(needles_matches, needle_matches, suggestions)
end


"""
	Search function for searching using the term imporatances associated to a corpus.
"""
function search(needles::Vector{S},
                term_counts::TermCounts;
                search_method::Symbol=:exact) where S<:AbstractString
    # Initializations
    p = length(needles)
    I = term_counts.column_indices
    V = term_counts.values
    m, n = size(term_counts.values)  # m - no. of documents, n - no. of terms+1
    inds = fill(n,p)  # default value n i.e. return 0-vector from V
    # Get needle mutating and string matching functions
    if search_method == :exact
        needle_mutator = identity
        matching_function = isequal
    else  # search_method == :regex
        needle_mutator = (arg::S)->Regex(arg)
        matching_function = occursin
    end
    # Mutate needles
    patterns = needle_mutator.(needles)
    # Search
    haystack = keys(I)
    empty_vector = Int[]
    if search_method == :exact
        for (j, pattern) in enumerate(patterns)
            inds[j] = get(I, pattern, n)
        end
    else  # search_method==:regex
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
    Search in the search tree for matches.
"""
function search_heuristically!(suggestions::MultiDict{String, Tuple{Float64, String}},
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



###################
# Semantic search #
###################
function search(searcher::SemanticSearcher{T,D,E,M},
                query;  # can be either a string or vector of strings
                search_type::Symbol=:metadata,
                search_method::Symbol=Symbol(),  #not used
                max_matches::Int=10,
                max_suggestions::Int=DEFAULT_MAX_CORPUS_SUGGESTIONS  # not used
                ) where
        {T<:AbstractId, D<:AbstractDocument, E, M<:AbstractEmbeddingModel}
    # Tokenize
    needles = extract_tokens(query)
    # Initializations
    n = size(searcher.model, 2)    # number of documents
    # Search metadata and/or data
    where_to_search = ifelse(search_type==:all,
                             [:data, :metadata],
                             [search_type])
    document_scores = zeros(Float64, n)     # document relevance
    query_embedding = get_document_embedding(searcher.embeddings,
                                             searcher.corpus.lexicon,
                                             query)
    for wts in where_to_search
        # search
        document_scores += search(query_embedding,
                                  searcher.embeddings[wts])
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
    return searcher.id, SearchResult(query_matches, needle_matches, suggestions)
end

function search(query_embedding::Vector{N}, embeddings::Matrix{N}) where N<:AbstractFloat
    # Cosine similarity
    embeddings'*query_embedding
end
