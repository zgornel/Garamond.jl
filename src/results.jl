#################################################
# Search results objects and associated methods #
#################################################

# Search results from a single corpus
struct CorpusSearchResult
    query_matches::MultiDict{Float64, Int}  # score => document indices
    needle_matches::Dict{String, Float64}  # needle => sum of scores
    suggestions::MultiDict{String, Tuple{Float64,String}} # needle => tuples of (score,partial match)
end


CorpusSearchResult() = CorpusSearchResult(
    MultiDict{Float64, Int}(),
    Dict{String, Float64}(),
    MultiDict{String, Tuple{Float64,String}}()
)


isempty(csr::T) where T<:CorpusSearchResult =
    all(isempty(getfield(csr, field)) for field in fieldnames(T))

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
show(io::IO, csr::CorpusSearchResult) = begin
    n = valength(csr.query_matches)
    nm = length(csr.needle_matches)
    ns = length(csr.suggestions)
    printstyled(io, "Search results for a corpus: ")
    printstyled(io, " $n hits, $nm query terms, $ns suggestions.", bold=true)
end


# Pretty printer of results
print_search_results(crps::Corpus, csr::CorpusSearchResult) = begin
    nm = valength(csr.query_matches)
    ns = length(csr.suggestions)
    printstyled("$nm search results")
    ch = ifelse(nm==0, ".", ":"); printstyled("$ch\n")
    for score in sort(collect(keys(csr.query_matches)), rev=true)
        for doc in (crps[i] for i in csr.query_matches[score])
            printstyled("  $score ~ ", color=:normal, bold=true)
            printstyled("$(metadata(doc))\n", color=:normal)
        end
    end
    ns > 0 && printstyled("$ns suggestions:\n")
    for (keyword, suggestions) in csr.suggestions
        printstyled("  \"$keyword\": ", color=:normal, bold=true)
        printstyled("$(join(map(x->x[2], suggestions), ", "))\n", color=:normal)
    end
end



# Search results for multiple corpora
struct CorporaSearchResult{T}
    corpus_results::Dict{T, CorpusSearchResult}  # Dict(score=>metadata)
    suggestions::MultiDict{String, String}
end


CorporaSearchResult{T}() where T<:AbstractId =
    CorporaSearchResult(
        Dict{T, CorpusSearchResult}(),
        MultiDict{String, String}()
)


isempty(csr::T) where T<:CorporaSearchResult =
    all(isempty(getfield(csr, field)) for field in fieldnames(T))


# Show method
show(io::IO, csr::CorporaSearchResult) = begin
    if !isempty(csr.corpus_results)
        nt = mapreduce(x->valength(x[2].query_matches), +, csr.corpus_results)
    else
        nt=0
    end
    matched_needles = unique(collect(needle for (_, _result) in csr.corpus_results
                                     for needle in keys(_result.needle_matches)))
    nmt = length(matched_needles)
    nst = length(csr.suggestions)
    printstyled(io, "Search results for $(length(csr.corpus_results)) corpora: ")
    printstyled(io, "$nt hits, $nmt query terms, $nst suggestions.\n", bold=true)
    for (id, _result) in csr.corpus_results
        n = valength(_result.query_matches)
        nm = length(_result.needle_matches)
        ns = length(_result.suggestions)
        printstyled(io, "`-[$id] ", color=:cyan)  # hash
        printstyled(io, "$n hits, $nm query terms, $ns suggestions\n")
    end
end


# Pretty printer of results
print_search_results(crpra_searcher::CorporaSearcher, csr::CorporaSearchResult) = begin
    nt = mapreduce(x->valength(x[2].query_matches), +, csr.corpus_results)
    printstyled("$nt search results from $(length(csr.corpus_results)) corpora\n")
    ns = length(csr.suggestions)
    for (id, _result) in csr.corpus_results
        crps = crpra_searcher[id].corpus
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


# Push method (useful for inserting CorpusSearcher search results
# into CorporaSearcher search results)
function push!(csr::CorporaSearchResult{T},
               sr::Pair{T, CorpusSearchResult}) where T<:AbstractId
    push!(csr.corpus_results, sr)
    return csr
end


# Update suggestions for multiple corpora search results
function update_suggestions!(csr::CorporaSearchResult{T},
                             max_suggestions::Int=1) where T<:AbstractId
    # Quickly exit if no suggestions are sought
    max_suggestions <=0 && return MultiDict{String, String}()
    if length(csr.corpus_results) > 1
        # Results from multiple corpora, suggestions have to
        # be processed somewhat:
        #  - keep only needles not found across all corpora
        #  - remove suggestions that correspond to found needles

        # Get the needles not found across all corpus results
        corpus_results = values(csr.corpus_results)
        matched_needles = (needle for _result in corpus_results
                           for needle in keys(_result.needle_matches))
        missed_needles = intersect((keys(_result.suggestions)
                                    for _result in corpus_results)...)
        # Construct suggestions for the whole CorporaSearcher
        for needle in missed_needles
            _tmpvec = Vector{Tuple{Float64,String}}()
            for _result in corpus_results
                if haskey(_result.suggestions, needle) &&
                   !(any(suggestion in matched_needles
                         for (_, suggestion) in _result.suggestions[needle]))
                   # Current key was not found and the suggestions
                   # for it are not found in the matched needles
                    _tmpvec = vcat(_tmpvec, _result.suggestions[needle])
                end
            end
            if !isempty(_tmpvec)
                sort!(_tmpvec, by=x->x[1])  # sort vector of tuples by distance
                # Keep results with the same distance even if the number is
                # larger than the maximum
                n = min(max_suggestions, length(_tmpvec))
                nn = 0
                d = -1.0
                for (i, (dist, _)) in enumerate(_tmpvec)
                    if i <= n || d == dist
                        d = dist
                        nn = i
                    end
                end
                push!(csr.suggestions, needle=>map(x->x[2],_tmpvec)[1:nn])
            end
        end
    else
        # Results from one corpus, easy situation, just copy the suggestions
        for (_, _result) in csr.corpus_results
            for (needle, vs) in _result.suggestions
                # vs is a Vector{Tuple{Float64, String}},
                # sorted by distance i.e. the float
                for v in vs
                    push!(csr.suggestions, needle=>v[2])
                end
            end
        end
    end
    return csr
end
