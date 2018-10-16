##################
# Search methods #
##################

# Function that searches through several corpora
function search(crpra::Corpora{T,D},
                needles::Vector{String};
                search_type::Symbol=DEFAULT_SEARCH_TYPE,
                search_method::Symbol=DEFAULT_SEARCH_METHOD,
                max_matches::Int=DEFAULT_MAX_MATCHES,
                max_suggestions::Int=DEFAULT_MAX_SUGGESTIONS,
                max_corpus_suggestions::Int=DEFAULT_MAX_CORPUS_SUGGESTIONS) where
        {T<:AbstractId, D<:AbstractDocument}
    # Checks
    @assert search_type in [:index, :metadata, :all]
    @assert search_method in [:exact, :regex]
    @assert max_matches >= 0
    @assert max_suggestions >= 0
    @assert max_corpus_suggestions >=0
    # Initializations
    result = CorporaSearchResult{T}()
    n = length(crpra.corpus)
    max_corpus_suggestions = min(max_suggestions, max_corpus_suggestions)
    # Search
    for (id, crps) in crpra.corpus
        if crpra.enabled[id]
            # Get corpus search results
            search_result = search(crps,
                                   needles,
                                   index=crpra.index[id],
                                   term_importances=crpra.term_importances[id],
                                   search_trees=crpra.search_trees[id],
                                   search_type=search_type,
                                   search_method=search_method,
                                   max_matches=max_matches,
                                   max_suggestions=max_corpus_suggestions)
            # Add corpus search results to the corpora search results
            push!(result, id=>search_result)
        end
    end
    !isempty(result) && update_suggestions!(result, max_suggestions)
    return result
end


"""
	search(crps, needles [;kwargs])

Searches for needles (i.e. key terms) in a corpus' metadata, text or both and 
returns the documents that match best the query. The function returns a 
vector of dictionaries representing the metadata of the best matching
documents.

# Arguments
  * `crps::Corpus{T}` is the text corpus
  * `needles::Vector{String}` is a vector of key terms representing the query

# Keyword arguments
  * `index::Dict{Symbol, Dict{String, Vector{Int}}}` document ans metadata reverse index
  * `search_trees::Dict{Symbol, BKTree{String}}` search trees used for approximate
     string matching i.e. for suggestion generation
  * `search_type::Symbol` is the type of the search; can be `:metadata` (default),
     `:index` or `:all`; the options specify that the needles can be found in
     the metadata of the documents of the corpus, their inverse index or both 
     respectively
  * `search_method::Symbol` controls the type of matching: `:exact` (default)
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
function search(crps::Corpus{D},
                needles::Vector{String};
                index::Dict{Symbol, Dict{String, Vector{Int}}}=
                    Dict{Symbol, Dict{String, Vector{Int}}}(),
                term_importances::Dict{Symbol, TermImportances}=
                    Dict{Symbol, TermImportances}(),
                search_trees::Dict{Symbol,BKTree{String}}=Dict{Symbol,BKTree{String}}(),
                search_type::Symbol=:metadata,
                search_method::Symbol=:exact,
                max_matches::Int=10,
                max_suggestions::Int=DEFAULT_MAX_CORPUS_SUGGESTIONS
               ) where {D<:AbstractDocument}
    # Initializations
    n = length(crps)		# Number of documents
    p = length(needles)		# Number of search terms
    # Search
    local M
    if search_type != :all
        M = search(needles, term_importances[search_type], search_method=search_method)
    else
        M = search(needles, term_importances[:index], search_method=search_method) +  # plus
            search(needles, term_importances[:metadata], search_method=search_method)
    end
    # Initializations of matched documents/needles
    document_scores = zeros(Float64, n)
    needle_popularity = zeros(Float64, p)
    @inbounds @simd for j in 1:p
         for i in 1:n
            if M[i,j] != 0.0
                document_scores[i]+= M[i,j]
                needle_popularity[j]+= M[i,j]
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
                                  search_trees[wts],
                                  needles_not_found,
                                  max_suggestions=max_suggestions)
        end
    end
    return CorpusSearchResult(query_matches, needle_matches, suggestions)
end


"""
	Search function for searching using the term imporatances associated to a corpus.
"""
function search(needles::Vector{String},
                term_importances::TermImportances;
                search_method::Symbol=:exact) where {T<:AbstractDocument}
    # Initializations
    p = length(needles)
    V = term_importances.values
    I = term_importances.column_indices
    m, n = size(V)  # m - no. of documents, n - no. of terms+1
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
    return view(V, :, inds)
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
