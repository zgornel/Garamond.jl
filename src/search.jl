# Function that matches whether a pattern is found in a specific field of a books vector
function match_by_field(pattern, books, field; ignorecase::Bool = true)
	
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
