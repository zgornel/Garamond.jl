# Overload ismatch to work matching any value within a vector
contains(sv::T, r::Regex) where T<:AbstractArray{S} where S<:AbstractString = any(contains(si,r) for si in sv);

# Overload lowervase function to work with vectors of strings
lowercase(v::T) where T<:AbstractArray{S} where S<:AbstractString = Base.lowercase.(v)

# Function that searches a regex pattern in a string vector
function search_regex(pattern, haystack; ignorecase::Bool = true)
	
	# Pre-allocate matches
	N = length(haystack)
	m = falses(N)

	# Construct a mutator function for ignoring cases
	ignorecase ? mutator = lowercase : mutator = x->x

	rpattern = Regex(mutator(pattern))
	
	# Loop and match
	for (i,hs) in enumerate(haystack)
		m[i] = contains(mutator(hs),rpattern)
		#if m[i] @show mutator(hs)=>rpattern end
	end

	return m
end



# Function that does the actual search
# we assume the match function fm is something of the form:
# 	fm(pattern, books, field) = match_exactly_by_field(pattern, books, field)
function search(patterns::Vector{String}, books::Vector{Book}; ignorecase::Bool = true, 
		 						heuristics::Bool = true, 
								heuristics_method::Symbol = :levenshtein, 
								MAX_MATCHES = 10)
	# Initializations
	N = length(books)
	P = length(patterns)
	searchfunc = search_regex								# Define matching functions 
	fields = [:author, :book, :publisher, :characteristics]					# Fields of books to search in
	nr = zeros(Int, N)									# Number of regex matches for each book
	nf = falses(P)										# Number of matched patterns for all books

	# Search for matches
	for (i,p) in enumerate(patterns)
		m = falses(N)
		for field in fields
			m .|= searchfunc(p, getfield.(books, field), ignorecase=ignorecase)	
		end
		nr += Int.(m)
		nf[i] = any(m)
	end
	
	# Simple heuristics suggestions if nothing is found
	suggestions = Dict{String,String}()
	if heuristics
		hsearchfunc = ifelse(heuristics_method == :levenshtein, levsort, fuzzysort) 
		if any(x->x==0, nf) # some patterns were not matched
			process_field_data(x::Vector{Vector{String}}) = vcat((x[i] for i in 1:length(x))...)
			process_field_data(x::Vector{String}) = x

			# Build a list with all the terms
			words = unique(
		      			vcat(
						searchquery_preprocess.(
		      					unique(vcat((process_field_data(getfield.(books, field)) for field in fields)...))
						)...
					)
			)

			# Search a suggestion for each word/pattern
			for (i,p) in enumerate(patterns)
				!nf[i] && push!(suggestions, p=>hsearchfunc(p, words)[1])
			end
		end
	end	


	# Order matches and select only those with a more than one match
	good_matches::Vector{Int} = setdiff(sortperm(nr,rev=true), find(x->x==0, nr))
	
	return book_to_dict.(books[good_matches[1:min(length(good_matches),MAX_MATCHES)]])
end
