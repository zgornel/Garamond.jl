##################
# Search methods #
##################

"""
	search(crpra_searcher, needles [;kwargs])

Searches for needles (i.e. key terms) in a multiple corpora and returns
information regarding the documents that match best the query.
The function returns an object of type CorporaSearchResult.

# Arguments
  * `crps_searcher::CorpusSearcher{T,D}` is the corpus searcher
  * `needles::Vector{String}` is a vector of key terms representing the query

# Keyword arguments
  * `search_type::Symbol` is the type of the search; can be `:metadata`,
     `:index` or `:all`; the options specify that the needles can be found in
     the metadata of the documents of the corpus, their inverse index or both
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
function search(crpra_searcher::CorporaSearcher{T,D,V},
                needles::Vector{String};
                search_type::Symbol=DEFAULT_SEARCH_TYPE,
                search_method::Symbol=DEFAULT_SEARCH_METHOD,
                max_matches::Int=DEFAULT_MAX_MATCHES,
                max_suggestions::Int=DEFAULT_MAX_SUGGESTIONS,
                max_corpus_suggestions::Int=DEFAULT_MAX_CORPUS_SUGGESTIONS) where
        {T<:AbstractId, D<:AbstractDocument, V<:AbstractVector}
    # Checks
    @assert search_type in [:index, :metadata, :all]
    @assert search_method in [:exact, :regex]
    @assert max_matches >= 0
    @assert max_suggestions >= 0
    @assert max_corpus_suggestions >=0
    # Initializations
    n = length(crpra_searcher.searchers)
    result = SharedVector{CorporaSearchResult{T}}(n)
    max_corpus_suggestions = min(max_suggestions, max_corpus_suggestions)
    # Search
    @sync @distributed for index in 1:n
        if crpra_searcher.searchers[index].enabled
            # Get corpus search results
            id, search_result = search(crpra_searcher.searchers[index],
                                   needles,
                                   search_type=search_type,
                                   search_method=search_method,
                                   max_matches=max_matches,
                                   max_suggestions=max_corpus_suggestions)
            result[index] = search_result
            # Add corpus search results to the corpora search results
        end
    end
    #!isempty(result) && update_suggestions!(result, max_suggestions)
    return result
end


"""
	search(crps_searcher, needles [;kwargs])

Searches for needles (i.e. key terms) in a corpus' metadata, text or both and 
returns information regarding the the documents that match best the query.
The function returns an object of type CorpusSearchResult and the id of the
CorpusSearcher.

# Arguments
  * `crps_searcher::CorpusSearcher{T,D}` is the corpus searcher
  * `needles::Vector{String}` is a vector of key terms representing the query

# Keyword arguments
  * `search_type::Symbol` is the type of the search; can be `:metadata`,
     `:index` or `:all`; the options specify that the needles can be found in
     the metadata of the documents of the corpus, their inverse index or both 
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
# Function that searches in a corpus'a metdata or metadata + content for needles (i.e. keyterms) 
function search(crps_searcher::CorpusSearcher{T,D},
                needles::Vector{String};
                search_type::Symbol=:metadata,
                search_method::Symbol=:exact,
                max_matches::Int=10,
                max_suggestions::Int=DEFAULT_MAX_CORPUS_SUGGESTIONS
               ) where {T<:AbstractId, D<:AbstractDocument}
    # Initializations
    n = length(crps_searcher.corpus)    # number of documents
    p = length(needles)                 # number of search terms
    # Search metadata and/or index
    where_to_search = ifelse(search_type==:all,
                             [:index, :metadata],
                             [search_type])
    document_scores = zeros(Float64, n)     # document relevance
    needle_popularity = zeros(Float64, p)   # needle relevance
    for wts in where_to_search
        # search
        inds = search(needles, crps_searcher.term_importances[wts], search_method=search_method)
        # select term importance vectors
        M = view(crps_searcher.term_importances[wts].values, :, inds)
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
    query_matches = MultiDict{Float64, Int}()
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
    suggestions = MultiDict{String, Tuple{Float64, String}}()
    missing_needles = map(iszero, needle_popularity)
    if max_suggestions > 0 && any(missing_needles)
        needles_not_found = needles[missing_needles]
        where_to_search = ifelse(search_type == :all,
                                 [:index, :metadata],
                                 [search_type])
        # Get suggestions
        for wts in where_to_search
            search_heuristically!(suggestions,
                                  crps_searcher.search_trees[wts],
                                  needles_not_found,
                                  max_suggestions=max_suggestions)
        end
    end
    return crps_searcher.id, CorpusSearchResult(query_matches, needle_matches, suggestions)
end


"""
	Search function for searching using the term imporatances associated to a corpus.
"""
function search(needles::Vector{String},
                term_importances::TermImportances;
                search_method::Symbol=:exact) where {T<:AbstractDocument}
    # Initializations
    p = length(needles)
    I = term_importances.column_indices
    V = term_importances.values
    m, n = size(term_importances.values)  # m - no. of documents, n - no. of terms+1
    inds = fill(n,p)  # default value n i.e. return 0-vector from V
    # Get needle mutating and string matching functions
    if search_method == :exact
        needle_mutator = identity
        matching_function = isequal
    else  # search_method == :regex
        needle_mutator = (arg::String)->Regex(arg)
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
                              needles::Vector{String};
                              max_suggestions::Int=1)
    if isempty(needles)
        return suggestions
    else  # there are terms that have not been found
        # Checks
        @assert !BKTrees.is_empty_node(search_tree.root) "FATAL: empty search tree."
        for needle in needles
            _suggestions = sort!(find(search_tree, needle,
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
