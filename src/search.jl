# Overload ismatch to work matching any value within a vector
contains(sv::T, r::Regex) where T<:AbstractArray{S} where S<:AbstractString = any(contains(si,r) for si in sv);

# Overload lowervase function to work with vectors of strings
lowercase(v::T) where T<:AbstractArray{S} where S<:AbstractString = Base.lowercase.(v)



"""
	search(needles, crps, search [;kwargs])

Searches for needles (i.e. key terms) in a corpus' metadata, text or both and 
returns the documents that match best the query. The function returns a 
vector of dictionaries representing the metadata of the best matching
documents.

# Arguments
  * `needles::Vector{String}` is a vector of key terms representing the query
  * `crps::Corpus{T}` is the text corpus
  * `search::Symbol` is the type of the search; can be `:metadata` (default),
     `:index` or `:all`; the options specify that the needles can be found in
     the metadata of the documents of the corpus, their inverse index or both 
     respectively

# Keyword arguments
  * `metadata_fields::Vector{Symbol}` are fields in metadata to search
  * `ignorecase::Bool` specifies whether to ignore the case
  * `heuristics::Bool` specifies whether to use heuristics
  * `heuristic::Bool` specifies what heuristics function to use
  * `MAX_MATCHES::Int` is the maximum number of search results to return
  * `WORD_SUGGESTIONS` is the maximum number of suggestions to return for 
     each missing needle

# Examples
```
	...
```
"""
# Function that searches in a corpus'a metdata or metadata + content for needles (i.e. keyterms) 
function search(crps::Corpus{T} where T<:AbstractDocument,
		needles::Vector{String};
		search::Symbol=:metadata,
		metadata_fields::Vector{Symbol}=[:author, :name, :publisher],
		ignorecase::Bool = true,
		heuristics::Bool = true,
		heuristic::Symbol = :levenshtein,
		MAX_MATCHES::Int = 10,
		WORD_SUGGESTIONS::Int = 1)

	# Initializations
	n = length(crps)									# Number of documents
	p = length(needles)									# Number of search terms
	matches = spzeros(Int, n, p)								# Match matrix
	
	# Search
	if search == :metadata
		matches += search_metadata(crps, needles, 
			     	metadata_fields=metadata_fields, 
			     	ignorecase=ignorecase)
	elseif search == :index
		matches += search_index(crps, needles, 
			  	ignorecase=ignorecase)
	elseif search == :all
		matches +=  search_metadata(crps, needles, 
			      	metadata_fields=metadata_fields, 
			      	ignorecase=ignorecase)
		matches += search_index(crps, needles,
			  	ignorecase=ignorecase)
	else
		error("Unknown search method.")
	end

	# Organize results
	needle_matches = vec(sum(matches,2)) 	# number of needles matched in each document (for sorting search quality)
	doc_matches = vec(sum(matches,1))	# number of documents matching each needle (for heuristics)
	
	# Heuristic search (try to find closest string)
	if heuristics
		suggestions = heuristic_search(crps, needles[doc_matches .== 0],
				  search=search, heuristic=heuristic, 
				  metadata_fields=metadata_fields,
				  word_suggestions=WORD_SUGGESTIONS)
	else 
		suggestions = Dict{String,Vector{String}}()
	end

	# Sort matches and obtain the indexes of best maches
	idxs::Vector{Int} = setdiff(sortperm(needle_matches,rev=true), find(iszero,needle_matches))

	return (dict.(metadata.(crps[idxs][1:min(MAX_MATCHES, length(idxs))])),
	 	suggestions)
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
function heuristic_search(crps::Corpus{T} where T<:AbstractDocument,
			  needles::Vector{String};
			  search::Symbol=:index,
			  heuristic::Symbol=:levenshtein,
			  metadata_fields::Vector{Symbol}=Symbol[],
			  word_suggestions::Int=1)

	# Initializations
	n = length(crps)
	h_search_func = ifelse(heuristic == :levenshtein, levsort, fuzzysort) 
	suggestions = Dict{String, Vector{String}}()

	if isempty(needles)
		return suggestions
	else # There are terms that have not been found
		if search == :metadata
			words = unique(searchquery_preprocess(join(
					      (metastring(crps[i],metadata_fields) for i in 1:length(crps)
	    					)," "))); 
		elseif search == :index
			@assert !isempty(inverse_index(crps)) "FATAL: The corpus has no inverse index."
			words = collect(keys(inverse_index(crps)))
		elseif search == :all
			@assert !isempty(inverse_index(crps)) "FATAL: The corpus has no inverse index."
			words = unique( [searchquery_preprocess(join(
						(metastring(crps[i],metadata_fields) for i in 1:length(crps)
	     					)," ")); 
		    			collect(keys(inverse_index(crps)))] )
		else
			error("Unknown search method.")
		end

		# Search a suggestion for each word/pattern
		ns = min(length(words),word_suggestions)
		for (i,needle) in enumerate(needles)
			push!(suggestions, needle=>h_search_func(needle, words)[1:ns])
		end
	end
	return suggestions
end
