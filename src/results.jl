#################################################
# Search results objects and associated methods #
#################################################

# Search results from a single corpus
struct SearchResult
    query_matches::MultiDict{Float64, Int}  # score => document indices
    needle_matches::Dict{String, Float64}  # needle => sum of scores
    suggestions::MultiDict{String, Tuple{Float64,String}} # needle => tuples of (score,partial match)
end


SearchResult() = SearchResult(
    MultiDict{Float64, Int}(),
    Dict{String, Float64}(),
    MultiDict{String, Tuple{Float64,String}}()
)


isempty(sr::T) where T<:SearchResult =
    all(isempty(getfield(sr, field)) for field in fieldnames(T))

# Calculate the length of a MultiDict as the number
# of values considering all keys
valength(md::MultiDict) = begin
    if isempty(md)
        return 0
    else
        return mapreduce(x->length(x[2]), +, md)
    end
end


# Show method
show(io::IO, sr::SearchResult) = begin
    n = valength(sr.query_matches)
    nm = length(sr.needle_matches)
    ns = length(sr.suggestions)
    printstyled(io, "Search results for a corpus: ")
    printstyled(io, " $n hits, $nm query terms, $ns suggestions.", bold=true)
end


# Pretty printer of results
print_search_results(srcher::AbstractSearcher, sr::SearchResult) = begin
    nm = valength(sr.query_matches)
    ns = length(sr.suggestions)
    printstyled("$nm search results")
    ch = ifelse(nm==0, ".", ":"); printstyled("$ch\n")
    for score in sort(collect(keys(sr.query_matches)), rev=true)
        for doc in (srcher.corpus[i] for i in sr.query_matches[score])
            printstyled("  $score ~ ", color=:normal, bold=true)
            printstyled("$(metadata(doc))\n", color=:normal)
        end
    end
    ns > 0 && printstyled("$ns suggestions:\n")
    for (keyword, suggestions) in sr.suggestions
        printstyled("  \"$keyword\": ", color=:normal, bold=true)
        printstyled("$(join(map(x->x[2], suggestions), ", "))\n", color=:normal)
    end
end



# Search results for multiple corpora
struct AggregateSearchResult{T}
    corpus_results::Dict{T, SearchResult}  # Dict(score=>metadata)
    suggestions::MultiDict{String, String}
end


AggregateSearchResult{T}() where T<:AbstractId =
    AggregateSearchResult(
        Dict{T, SearchResult}(),
        MultiDict{String, String}()
)


isempty(sr::T) where T<:AggregateSearchResult =
    all(isempty(getfield(sr, field)) for field in fieldnames(T))


# Show method
show(io::IO, sr::AggregateSearchResult) = begin
    if !isempty(sr.corpus_results)
        nt = mapreduce(x->valength(x[2].query_matches), +, sr.corpus_results)
    else
        nt=0
    end
    matched_needles = unique(
        collect(needle for (_, _result) in sr.corpus_results
        for needle in keys(_result.needle_matches)))
    nmt = length(matched_needles)
    nst = length(sr.suggestions)
    printstyled(io, "Search results for $(length(sr.corpus_results)) corpora: ")
    printstyled(io, "$nt hits, $nmt query terms, $nst suggestions.\n", bold=true)
    for (id, _result) in sr.corpus_results
        n = valength(_result.query_matches)
        nm = length(_result.needle_matches)
        ns = length(_result.suggestions)
        printstyled(io, "`-[$id] ", color=:cyan)  # hash
        printstyled(io, "$n hits, $nm query terms, $ns suggestions\n")
    end
end


# Pretty printer of results
print_search_results(agg_srcher::AggregateSearcher,
                     sr::AggregateSearchResult) = begin
    if !isempty(sr.corpus_results)
        nt = mapreduce(x->valength(x[2].query_matches), +, sr.corpus_results)
    else
        nt = 0
    end
    printstyled("$nt search results from $(length(sr.corpus_results)) corpora\n")
    ns = length(sr.suggestions)
    for (id, _result) in sr.corpus_results
        crps = agg_srcher[id].corpus
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
    for (keyword, suggestions) in sr.suggestions
        printstyled("  \"$keyword\": ", color=:normal, bold=true)
        printstyled("$(join(suggestions, ", "))\n", color=:normal)
    end
end


# Push method (useful for inserting AbstractSearcher search results
# into AggregateSearcher search results)
function push!(agg_sr::AggregateSearchResult{T},
               sr::Pair{T, SearchResult}) where T<:AbstractId
    push!(agg_sr.corpus_results, sr)
    return agg_sr
end


# Squash suggestions for multiple corpora search results
function squash_suggestions!(sr::AggregateSearchResult{T},
                             max_suggestions::Int=1) where T<:AbstractId
    # Quickly exit if no suggestions are sought
    max_suggestions <=0 && return MultiDict{String, String}()
    if length(sr.corpus_results) > 1
        # Results from multiple corpora, suggestions have to
        # be processed somewhat:
        #  - keep only needles not found across all corpora
        #  - remove suggestions that correspond to found needles

        # Get the needles not found across all corpus results
        corpus_results = values(sr.corpus_results)
        matched_needles = (needle for _result in corpus_results
                           for needle in keys(_result.needle_matches))
        missed_needles = intersect((keys(_result.suggestions)
                                    for _result in corpus_results)...)
        # Construct suggestions for the whole AggregateSearcher
        for needle in missed_needles
            needle_suggestions_corpora = Vector{Tuple{Float64,String}}()
            for _result in corpus_results
                if haskey(_result.suggestions, needle) &&
                   !(any(suggestion in matched_needles
                         for (_, suggestion) in _result.suggestions[needle]))
                   # Current key was not found and the suggestions
                   # for it are not found in the matched needles
                   union!(needle_suggestions_corpora,
                          _result.suggestions[needle])
                end
            end
            if !isempty(needle_suggestions_corpora)
                sort!(needle_suggestions_corpora, by=x->x[1])  # sort vector of tuples by distance
                # Keep results with the same distance even if the number is
                # larger than the maximum
                n = min(max_suggestions, length(needle_suggestions_corpora))
                nn = 0
                d = -1.0
                for (i, (dist, _)) in enumerate(needle_suggestions_corpora)
                    if i <= n || d == dist
                        d = dist
                        nn = i
                    end
                end
                push!(sr.suggestions,
                      needle=>map(x->x[2], needle_suggestions_corpora)[1:nn])
            end
        end
    else
        # Results from one corpus, easy situation, just copy the suggestions
        for (_, _result) in sr.corpus_results
            for (needle, vs) in _result.suggestions
                # vs is a Vector{Tuple{Float64, String}},
                # sorted by distance i.e. the float
                for v in vs
                    push!(sr.suggestions, needle=>v[2])
                end
            end
        end
    end
    return sr
end
