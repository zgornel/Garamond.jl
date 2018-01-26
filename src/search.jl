# Overload ismatch to work matching any value within a vector
ismatch(r::Regex, sv::T) where T<:AbstractArray{S} where S<:AbstractString = any(ismatch(r,si) for si in sv);

# Overload lowervase function to work with vectors of strings
lowercase(v::T) where T<:AbstractArray{S} where S<:AbstractString = Base.lowercase.(v)

# Function that matches whether a pattern is found in a specific field of a books vector
function match_exactly_by_field(pattern::AbstractString, books::Vector{Book}, field::Symbol; ignorecase::Bool = true)
	
	# Pre-allocate matches
	N = length(books)
	m = falses(N)

	# Construct a mutator function for ignoring cases
	ignorecase ? mutator = lowercase : mutator = x->x

	rpattern = Regex(mutator(pattern))
	fieldvals = getfield.(books, field)
	
	# Loop and match
	for (i,val) in enumerate(fieldvals)
		m[i] = ismatch(rpattern, mutator(val))
	end

	return m
end



# Function that does the actual search
# we assume the match function fm is something of the form:
# 	fm(pattern, books, field) = match_exactly_by_field(pattern, books, field)
function matcher(patterns::Vector{String}, books::Vector{Book})

	# Define matching functions
	fm = (p::String,b::Vector{Book},f::Symbol)->match_exactly_by_field(p,b,f)

	# Initialize fields
	fields = [:author, :book, :publisher, :characteristics]

	# Search for matches
	matches = zeros(Int, length(books))
	for p in patterns
		for fi in fields	
			matches += fm(p,books, fi) 
		end
	end
	
	# Order matches and select only those with a more than one match
	good_matches = setdiff(sortperm(matches,rev=true), find(x->x==0, matches))
	
	return book_to_dict.(books[good_matches])
end
