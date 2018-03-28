#########################
# Interface for Corpora #
#########################
abstract type AbstractCorpora end

# CorpusRefs can be built from a data configuration file or manually
mutable struct CorpusRef
	path::String				# file/directory path
	name::String				# name of corpus
	parser::Function			# file/directory parser function used to obtain corpus
	enabled::Bool				# whether to use the corpus in search or not
end

CorpusRef() = CorpusRef("","",identity, false)

Base.show(io::IO, cref::CorpusRef) = print(io, "CorpusRef for $(cref.name)")



# Corpora can be built from a .garamond configuration file or from a vector of CorpusRef's
mutable struct Corpora <: AbstractCorpora	# the 'hash' identifies the corpus
	corpora::Dict{UInt, Corpus}		# hash --> corpus
	refs::Dict{UInt, CorpusRef}		# hash --> corpus name
	enabled::Dict{UInt, Bool}		# whether to use the corpus in search or not
end

Corpora() = Corpora(Dict{UInt, Corpus}(), Dict{UInt, CorpusRef}(), Dict{UInt, Bool}())

Base.show(io::IO, crpra::Corpora) = begin
	print(io, "$(length(crpra.corpora))-element Corpora:\n")
	for (h, crps) in crpra.corpora
		print(io, " 0x$(hex(h)) => $(crpra.refs[h].name):")
		println(io, " $(crps) [$(crpra.enabled[h] ? "Enabled" : "Disabled")]")
	end
end



#TODO: Additional methods for Corpora: delete!, keys, various updates, file checks, etc.

# Various iterators over parts of a Corpora
keys(crpra::Corpora) = keys(crpra.corpora)
values(crpra::Corpora) = ((crpra.corpora[k], crpra.refs[k], crpra.enabled[k]) for k in keys(crpra.corpora))
names(crpra::Corpora) = (ref.name for ref in values(books.refs))

function update_lexicon!(crpra::Corpora)
	for c in values(crpra.corpora)
		TextAnalysis.update_lexicon!(c)
	end
end

function update_inverse_index!(crpra::Corpora)
	for c in values(crpra.corpora)
		TextAnalysis.update_inverse_index!(c)
	end
end



###############################################################
# Utils for interfacing with TextAnalysis.jl and Languages.jl #
###############################################################

#Printer for TextAnalysis metadata
show(io::IO, md::TextAnalysis.DocumentMetadata) = 
	print(io,"TextAnalysis.DocumentMetadata ~ id=$(md.id) \"$(md.name)\" by $(md.author) from $(md.published_year)")

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
