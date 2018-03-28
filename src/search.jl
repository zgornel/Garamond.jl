# Overload ismatch to work matching any value within a vector
contains(sv::T, r::Regex) where T<:AbstractArray{S} where S<:AbstractString = 
	any(contains(si,r) for si in sv);

# Overload lowervase function to work with vectors of strings
lowercase(v::T) where T<:AbstractArray{S} where S<:AbstractString =
	Base.lowercase.(v)



# Function that searches through several corpora
function search(crpra::T where T<:AbstractCorpora,
		needles::Vector{String}; 
		search_method::Symbol=:metadata,
		metadata_fields::Vector{Symbol}=[:author, :name, :publisher],
		ignorecase::Bool = true,
		heuristic::Symbol = :levenshtein,
		MAX_MATCHES::Int = 10,
		WORD_SUGGESTIONS::Int = 1)
	
	results = Dict{UInt, Vector{Dict{String, String}}}()
	suggestions = Dict{String, Set{String}}()
	for (h, crps) in crpra.corpora
		if crpra.enabled[h]
			ridx, sugg = search(crps, needles,
					search_method=search_method, 
			 		metadata_fields=metadata_fields,
					ignorecase=ignorecase,
					heuristic=heuristic,
					MAX_MATCHES=MAX_MATCHES,
					WORD_SUGGESTIONS=WORD_SUGGESTIONS)

			push!(results, h=>dict.(metadata.(crps[ridx])))
			for (ks, vs) in sugg
				if ks in keys(suggestions)
					union!(suggestions[ks], vs)
				else
					push!(suggestions, ks=>vs)
				end
			end
		end
	end
	return results, suggestions
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
  * `search_method::Symbol` is the type of the search; can be `:metadata` (default),
     `:index` or `:all`; the options specify that the needles can be found in
     the metadata of the documents of the corpus, their inverse index or both 
     respectively
  * `metadata_fields::Vector{Symbol}` are fields in metadata to search
  * `ignorecase::Bool` specifies whether to ignore the case
  * `heuristic::Symbol` specifies what heuristic function to use for
    missing strings matching; can be :levenshtein (default), :fuzzy or :none
  * `MAX_MATCHES::Int` is the maximum number of search results to return
  * `WORD_SUGGESTIONS::Int` is the maximum number of suggestions to return for 
     each missing needle

# Examples
```
	...
```
"""
# Function that searches in a corpus'a metdata or metadata + content for needles (i.e. keyterms) 
function search(crps::Corpus{T} where T<:AbstractDocument,
		needles::Vector{String};
		search_method::Symbol=:metadata,
		metadata_fields::Vector{Symbol}=[:author, :name, :publisher],
		ignorecase::Bool = true,
		heuristic::Symbol = :levenshtein,
		MAX_MATCHES::Int = 10,
		WORD_SUGGESTIONS::Int = 1)

	# Initializations
	n = length(crps)		# Number of documents
	p = length(needles)		# Number of search terms
	matches = spzeros(Int, n, p)	# Match matrix
	
	# Search
	if search_method == :metadata
		matches += search_metadata(crps, needles, 
			     	metadata_fields=metadata_fields, 
			     	ignorecase=ignorecase)
	elseif search_method == :index
		matches += search_index(crps, needles, 
			  	ignorecase=ignorecase)
	elseif search_method == :all
		matches +=  search_metadata(crps, needles, 
			      	metadata_fields=metadata_fields, 
			      	ignorecase=ignorecase)
		matches += search_index(crps, needles,
			  	ignorecase=ignorecase)
	else
		error("Unknown search method.")
	end
	
	# Number of needles matched in each document (for sorting search quality)
	needle_matches = vec(sum(matches,2)) 	

	# Number of documents matching each needle (for heuristics)
	doc_matches = vec(sum(matches,1))	
	
	# Try to find closest string
	suggestions = search_heuristically(crps,
			 	needles[doc_matches .== 0],
			 	search_method=search_method,
			 	heuristic=heuristic,
			 	metadata_fields=metadata_fields,
			 	word_suggestions=WORD_SUGGESTIONS)

	idxs::Vector{Int} = setdiff(sortperm(needle_matches,rev=true), find(iszero,needle_matches))
	resize!(idxs, min(MAX_MATCHES, length(idxs)))
	return idxs, suggestions
end



"""
	Search function for searching in the metadata of the documents in a corpus.
"""
function search_metadata(crps::Corpus{T} where T<:AbstractDocument,
			 needles::Vector{String};
			 metadata_fields::Vector{Symbol}=Symbol[],
			 ignorecase::Bool=true)

	n = length(crps)
	p = length(needles)
	matches = spzeros(Int, n, p)
	patterns = Regex.(needles)
	mutator = ifelse(ignorecase, lowercase, identity)

	# Search
	for (j, pattern) in enumerate(patterns)
		for (i, meta) in enumerate(metadata(crps))
			for field in metadata_fields
				if contains(mutator(getfield(meta, field)), pattern)
					matches[i,j]+=1
					break # from 'for field...'
				end
			end
		end
	end
	return matches
end



"""
	Search function for searching in the inverse index of a corpus.
"""
function search_index(crps::Corpus{T} where T<:AbstractDocument,
		      needles::Vector{String};
		      ignorecase::Bool=true)

	n = length(crps)
	p = length(needles)
	matches = spzeros(Int, n, p)
	patterns = Regex.(needles)
	invidx = inverse_index(crps)
	mutator = ifelse(ignorecase, lowercase, identity)
	
	# Check that inverse index exists
	@assert !isempty(inverse_index(crps)) "FATAL: The corpus has no inverse index."
	
	# Search
	for (j, pattern) in enumerate(patterns)
		for k in keys(invidx)
			if contains(mutator(k), pattern)
				matches[invidx[k], j]+=1
			end
		end
	end
	return matches 
end



# TODO: Combine heuristic with partial matches as well (i.e. heuristic suggestions only from entries with partial matches
# TODO: Full heuristics for no match: find best match(es) --> search for recommendations from entries corresponding to these best matches
"""
	Heuristically search for best matches for a list of needles (not found otherwise) in a corpus
"""
function search_heuristically(crps::Corpus{T} where T<:AbstractDocument,
			  needles::Vector{String};
			  search_method::Symbol=:index,
			  heuristic::Symbol=:levenshtein,
			  metadata_fields::Vector{Symbol}=Symbol[],
			  word_suggestions::Int=1)

	# Initializations
	n = length(crps)
	use_heuristic = true
	suggestions = Dict{String, Set{String}}()

	if heuristic == :levenshtein 
		h_search_func = levsort
	elseif heuristic == :fuzzy
		h_search_func = fuzzysort
	else
		h_search_func = identity
		use_heuristic = false
	end
	
	if use_heuristic
		if isempty(needles)
			return suggestions
		else # There are terms that have not been found
			if search_method == :metadata
				words = unique(prepare!(join(
						      (metastring(crps[i],metadata_fields) for i in 1:length(crps)
							)," "),QUERY_STRIP_FLAGS)); 
			elseif search_method == :index
				@assert !isempty(inverse_index(crps)) "FATAL: The corpus has no inverse index."
				words = collect(keys(inverse_index(crps)))
			elseif search_method == :all
				@assert !isempty(inverse_index(crps)) "FATAL: The corpus has no inverse index."
				words = unique( [prepare!(join(
							(metastring(crps[i],metadata_fields) for i in 1:length(crps)
							)," "),QUERY_STRIP_FLAGS); 
						collect(keys(inverse_index(crps)))] )
			else
				error("Unknown search method.")
			end

			# Search a suggestion for each word/pattern
			ns = min(length(words),word_suggestions)
			for (i,needle) in enumerate(needles)
				push!(suggestions, needle=>Set(h_search_func(needle, words)[1:ns]))
			end
		end
	end
	return suggestions
end
