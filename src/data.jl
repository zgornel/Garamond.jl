# Useful regular expressions
# - replace middle initial replace.(select(tt2,2),r"([A-Z]\s|[A-Z]\.\s)","")
# - replace end spaces replace.(select(tt2,2),r"[\s]+$","")

abstract type AbstractCorpora end



###############################################################
# Utils for interfacing with TextAnalysis.jl and Languages.jl #
###############################################################

#Printer for TextAnalysis metadata
show(io::IO, md::TextAnalysis.DocumentMetadata) = 
	print("TextAnalysis.DocumentMetadata ~ id=$(md.id) \"$(md.name)\" by $(md.author) from $(md.published_year))")

# Function that returns a Languages.Language from a language string i.e. "english" to Languages.EnglishLanguage
function get_language(l::AbstractString)
	default_language = Languages.EnglishLanguage
	languages = Dict(
		  "danish" => Languages.DanishLanguage,
		  "dutch" => Languages.DutchLanguage,
		  "english" => Languages.EnglishLanguage,
		  "finnish" => Languages.FinnishLanguage,
		  "french" => Languages.FrenchLanguage,
		  "german" => Languages.GermanLanguage,
		  "hungarian" => Languages.HungarianLanguage,
		  "italian" => Languages.ItalianLanguage,
		  "norwegian" => Languages.NorwegianLanguage,
		  "portuguese" => Languages.PortugueseLanguage,
		  "romanian" => Languages.RomanianLanguage,
		  "russian" => Languages.RussianLanguage,
		  "spanish" => Languages.SpanishLanguage,
		  "swedish" => Languages.SwedishLanguage,
		  "turkish" => Languages.TurkishLanguage
		  )
	return get(languages, strip(lowercase(l)), default_language)
end

# Function that returns a language string from a Languages.Language i.e. "english" from Languages.EnglishLanguage
function get_langstring(l::Type{<:Languages.Language})::String
	unknown_language = "unknown" 
	languages = Dict(
		  Languages.DanishLanguage => "danish",
		  Languages.DutchLanguage => "dutch",
		  Languages.EnglishLanguage => "english",
		  Languages.FinnishLanguage => "finnish",
		  Languages.FrenchLanguage => "french",
		  Languages.GermanLanguage => "german",
		  Languages.HungarianLanguage => "hungarian",
		  Languages.ItalianLanguage => "italian",
		  Languages.NorwegianLanguage => "norwegian",
		  Languages.PortugueseLanguage => "portugese",
		  Languages.RomanianLanguage => "romanian",
		  Languages.RussianLanguage => "russian",
		  Languages.SpanishLanguage => "spanish",
		  Languages.SwedishLanguage => "swedish",
		  Languages.TurkishLanguage => "turkish"
		  )
	return get(languages, l, unknown_language)
end

# Convert a language object to a string 
convert(::Type{S}, l::Type{T}) where {T<:Languages.Language, S<:AbstractString} = get_langstring(l)

# Convert a TextAnalysis metadata structure to a Dict
function dict(md::TextAnalysis.DocumentMetadata) 
	Dict{String,String}((String(field)=>getfield(md,field) for field in fieldnames(md)))
end



# Medatadata getter for documents
metadata(document::D where D<:TextAnalysis.AbstractDocument) = document.metadata
metadata(crps::C where C<:TextAnalysis.Corpus) = [crps[i].metadata for i in 1:length(crps)]

# Turn the document metadata into a string
function metastring(document::T where T<: TextAnalysis.AbstractDocument, 
		    fields::Vector{Symbol}=[:author, :name, :publisher])
	metastring(metadata(document), fields)
end

function metastring(md::TextAnalysis.DocumentMetadata, 
		    fields::Vector{Symbol}=[:author, :name, :publisher])
	join([getfield(md,field) for field in fields]," ")
end



#Insert metadata the text of the corpus documents.
const TEXT_STRIP = strip_case + strip_numbers + strip_punctuation +
		strip_articles + strip_non_letters + strip_stopwords + 
		strip_prepositions + strip_whitespace

function corpus_preparator!(crps::C where C<:TextAnalysis.Corpus, 
			    operations = TEXT_STRIP)
	prepare!(crps, operations)
end



################
# Data Loading #
################
"""
Define the csv parser configuration. It maps the fields from a delimited files 
to document metadata fields through the values associated to the ':medatadata' 
key and specifies whether a field is to be included or not in the document text 
through the :data value associated to the ':data' key
"""
mutable struct CSVParserConfig
	metadata::Dict{Int, Symbol}
	data::Dict{Int, Bool}
end

CSVParserConfig()= CSVParserConfig(Dict(1=>:id,
					 2=>:author,
					 3=>:name,
					 4=>:publisher,
					 5=>:edition_year,
					 6=>:published_year,
					 8=>:documenttype,
					 ),
			 	Dict(1=>false, 2=>true, 3=>true, 4=>true,
				     5=>false, 6=>false, 7=>false, 8=>true, 
				     9=>true, 10=>false)
)

# Function that returns a corpus from a delimited file; 
# the individual document metadata and text are filled according 
# to the config::CSVParserConfig
function parse_csv(file::AbstractString, config::CSVParserConfig=CSVParserConfig(); 
		   delim::Char = ',', header::Bool = true)
	
	# Pre-allocate
	vsd = Vector{StringDocument}()
	
	# Open file
	f = open(file, "r")

	# Select and sort the line fields which will be used as 
	# document text in the corpus
	mask = sort([k for k in keys(config.data) if config.data[k]])

	# Iterate and parse
	li = 1
	while !eof(f)
		if li==1 && header
			line = readline(f)
			li+=1
			continue
		else
			line = readline(f)
			vline = String.(split(line, delim))
			sd = StringDocument(join(vline[mask]," "))		# Set document data	
			for (column, metafield) in config.metadata		# Set document metadata
				setfield!(sd.metadata, metafield, vline[column])
			end
			language!(sd, Languages.EnglishLanguage)		# language (csv written in English) 
			
			push!(vsd, sd)
		end
	end

	# create and post-process corpus
	crps = Corpus(vsd)
	corpus_preparator!(crps)
	
	# Update lexicon and inverse index
	update_lexicon!(crps)
	update_inverse_index!(crps)

	return crps
end
