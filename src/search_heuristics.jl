if VERSION < v"0.7"

"""
    popfirst!(collection) -> item

Remove the first `item` from `collection`.

# Examples
```jldoctest
julia> A = [1, 2, 3, 4, 5, 6]
6-element Array{Int64,1}:
 1
 2
 3
 4
 5
 6

julia> popfirst!(A)
1

julia> A
5-element Array{Int64,1}:
 2
 3
 4
 5
 6
```
"""
function popfirst!(a::Vector)
    if isempty(a)
        throw(ArgumentError("array must be non-empty"))
    end
    item = a[1]
    ccall(:jl_array_del_beg, Void, (Any, UInt), a, 1)
    return item
end

end # if VERSION



function matchinds(needle, haystack; acronym = false)
	chars = collect(needle)
	is = Int[]
	lastc = '\0'
	for (i, char) in enumerate(haystack)
		isempty(chars) && break
		while chars[1] == ' ' popfirst!(chars) end # skip spaces
		if lowercase(char) == lowercase(chars[1]) && (!acronym || !isalpha(lastc))
			push!(is, i)
			popfirst!(chars)
		end
		lastc = char
	end
	return is
end



longer(x, y) = length(x) ≥ length(y) ? (x, true) : (y, false)

bestmatch(needle, haystack) =
	longer(matchinds(needle, haystack, acronym = true),
		matchinds(needle, haystack))

avgdistance(xs) = isempty(xs) ? 0 : (xs[end] - xs[1] - length(xs)+1)/length(xs)

function fuzzyscore(needle, haystack)
	score = 0.
	is, acro = bestmatch(needle, haystack)
	score += (acro ? 2 : 1)*length(is) # Matched characters
	score -= 2(length(needle)-length(is)) # Missing characters
	!acro && (score -= avgdistance(is)/10) # Contiguous
	!isempty(is) && (score -= mean(is)/100) # Closer to beginning
	return score
end

# Sort candidates by their Fuzzy distance with respect to a search term 
function fuzzysort(search, candidates)
	scores = pmap(cand -> (fuzzyscore(search, cand),
				-levenshtein(search, cand)), candidates)
	candidates[sortperm(scores)] |> reverse
end



# Levenshtein Distance
function levenshtein(s1, s2)
	a, b = collect(s1), collect(s2)
	m = length(a)
	n = length(b)
	d = zeros(Int, m+1, n+1)

	d[1:m+1, 1] = 0:m
	d[1, 1:n+1] = 0:n

	for i = 1:m, j = 1:n
	d[i+1,j+1] = min(d[i  , j+1] + 1,
			 d[i+1, j  ] + 1,
			 d[i  , j  ] + (a[i] != b[j]))
	end

	return d[m+1, n+1]
end

# Sort candidates by their Levenshtein distance with respect to a search term 
function levsort(search, candidates; κ::Int = 3)
	scores = map(cand -> (levenshtein(search, cand),
		              -fuzzyscore(search, cand)), candidates)
	candidates = candidates[sortperm(scores)]
	k = 0
	for i = 1:length(candidates)
		k += 1
		levenshtein(search, candidates[i]) > κ && break
	end
	return candidates[1:k]
end

