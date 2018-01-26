# Useful regular expressions
# - replace middle initial replace.(select(tt2,2),r"([A-Z]\s|[A-Z]\.\s)","")
# - replace end spaces replace.(select(tt2,2),r"[\s]+$","")

abstract type AbstractItem end

abstract type AbstractBook <: AbstractItem end

mutable struct Book <: AbstractBook
	id::Int
	author::Vector{String}
	book::String
	publisher::String
	year_apparition::Int
	year_published::Int
	language::String
	booktype::String
	characteristics::Vector{String}
	location::String
end



# Printer
Base.show(io::IO, book::T where T <: AbstractBook) = begin 
	if length(book.author) == 1
		print(io, "\"$(book.book)\" by $(book.author[1]) ~ $(book.publisher), $(book.year_published)")
	else
		print(io, "\"$(book.book)\" by $(book.author[1]) et al. ~ $(book.publisher), $(book.year_published)")
	end
end



# Convert methods
convert(::Type{Dict}, b::Garamond.Book) = Dict{String,Any}((String(field)=>getfield(b,field) for field in fieldnames(b)))
#convert(::Type{S}, b::Garamond.Book) where {S>:Book} = error("Conversion from $S to Book not possible")



# Function that returns a vector of books from a delimited file
function parse_books(booktype::Type{<:AbstractBook}, file::T where T <:AbstractString; 
		     delim::Char = ',', header::Bool = true)
	
	# Pre-allocate
	out = Vector{booktype}()
	
	# Open file
	f = open(file, "r")

	# Iterate and parse
	li = 1
	while !eof(f)
		if li==1 && header
			line = readline(f)
			li+=1
			continue
		else
			line = readline(f)
			v = split(line, delim)

			# Process fields
			b = Book(parse(Int, v[1]), 			# id
				String.(split(strip(v[2]),",")),	# author
				strip(v[3]),				# book
				strip(v[4]),				# publisher
				parse(Int, v[5]),			# year_apparition
				parse(Int, v[6]),			# year_published
				strip(v[7]),				# language
				strip(v[8]),				# booktype
				String.(split(v[9], r"(,|\s)+")),	# characteristics
				strip(v[10])				# location
			)
			push!(out, b)
		end
	end

	return out
end
