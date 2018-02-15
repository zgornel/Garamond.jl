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
  * `heuristics_method::Bool` specifies what heuristics function to use
  * `MAX_MATCHES::Int` is the maximum number of search results to return
  * `MAX_SUGGESTIONS` is the maximum number of suggestions to return for each missing needle

# Examples
```
	...
```
"""
# Function that searches in a corpus'a metdata or metadata + content for needles (i.e. keyterms) 
function search(crps::Corpus{T} where T<:AbstractDocument,
		needles::Vector{String},
		search::Symbol=:metadata;
		metadata_fields::Vector{Symbol}=[:author, :name, :publisher],
		ignorecase::Bool = true,
		heuristics::Bool = true,
		heuristics_method::Symbol = :levenshtein,
		MAX_MATCHES::Int = 10,
		MAX_SUGGESTIONS::Int = 1)

	# Initializations
	n = length(crps)									# Number of documents
	p = length(needles)									# Number of search terms
	matches = spzeros(Int, n, p)								# Match matrix
	
	# Search
	if search == :metadata
		matches += search_metadata(crps, needles, metadata_fields, ignorecase)
	elseif search == :index
		matches += search_index(crps, needles, ignorecase)
	elseif search == :all
		matches +=  search_metadata(crps, needles, metadata_fields, ignorecase)
		matches += search_index(crps, needles, ignorecase)
	else
		error("Unknown search method.")
	end

	# Organize results
	docmatches = vec(sum(matches,2)) 	# number of needles matched in each document (for sorting search quality)
	docneedles = vec(sum(matches,1))	# number of documents matching each needle (for heuristics)
	
	# Sort matches and obtain the indexes of best maches; return corresponding data
	idxs = setdiff(sortperm(docmatches,rev=true), find(iszero,docmatches))
	return dict.(metadata.(crps[idxs][1:min(MAX_MATCHES, length(idxs))]))


	# Heuristics (not working for now)
	#=
	# Simple heuristics suggestions if nothing is found
	# TODO: Combine heuristic with partial matches as well (i.e. heuristic suggestions only from entries with partial matches
	# TODO: Full heuristics for no match: find best match(es) --> search for recommendations from entries corresponding to these best matches
	suggestions = Dict{String,Vector{String}}()
	if heuristics
		hsearchfunc = ifelse(heuristics_method == :levenshtein, levsort, fuzzysort) 
		if !any(found) # no patterns were not matched
			# Build a list with all the terms
			words = unique(vcat(
		       		searchquery_preprocess.(
					unique(vcat(
		 				(getfield.(vmetadata, field) for field in fields)...
							)
		   				)
					)... # searchquery_preprocess
				)) # unique(vcat(

			# Search a suggestion for each word/pattern
			s = min(length(words), MAX_SUGGESTIONS)
			for (i,p) in enumerate(needles)
				!found[i] && push!(suggestions, p=>hsearchfunc(p, words)[1:s])
			end
		end
	end	
	=#
end



"""
	Search function for searching in the metadata of the documents in a corpus.
"""
function search_metadata(crps::Corpus{T} where T<:AbstractDocument,
			 needles::Vector{String},
			 metadata_fields::Vector{Symbol}, 
			 ignorecase::Bool)

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
		      needles::Vector{String},
		      ignorecase::Bool)
	
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








