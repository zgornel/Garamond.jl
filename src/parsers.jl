###################################################
# Data Loading - related functions and structures #
###################################################
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



# Load corpora using a Garamond data config file
function load_corpora(dataconfigpath::AbstractString)
	crefs = parse_data_config(dataconfigpath)
	load_corpora(crefs)
end

# Load corpora using a vector of corpus references
function load_corpora(crefs::Vector{CorpusRef})
	crpra = Corpora()
	for cref in crefs
		crps = cref.parser(cref.path)
		h = hash(crps)
		push!(crpra.corpora, h=>crps)
		push!(crpra.refs, h=>cref)
		push!(crpra.enabled, h=>cref.enabled) # all corpora enabled by default
	end

	return crpra
end



# Function that creates corpus references using a Garamond data config file
function parse_data_config(dataconfigpath::AbstractString) 
	crefs = Vector{CorpusRef}()
	
	open(dataconfigpath, "r") do f
		# Start parsing
		li = 1
		entry_counter = 0
		while !eof(f)
			line = strip(readline(f))
			if startswith(line, "#") 
				continue # skip comments
			elseif startswith(line, "[") # start of entry
				entry_counter += 1
				push!(crefs, CorpusRef())
				crefs[entry_counter].name = replace(line, r"(\[|\])", "")
			elseif contains(line, "=") # opt = val line
				opt, val = strip.(split(line,"="))
				if opt == "parser" && !isempty(val)
					crefs[entry_counter].parser = get_parser_function(val)
				elseif opt == "path" && !isempty(val)
					crefs[entry_counter].path = val
				elseif opt == "enabled" && !isempty(val)
					crefs[entry_counter].enabled = Bool(parse(val))
				else
					warn("Line $li in $(dataconfigpath): unrecognized option or empty option.")
					continue
				end
			else 
				continue # skip un-parsable line
			end
			li += 1
		end
	end

	return crefs
end



# Small enum of parsers
function get_parser_function(pname::AbstractString)
	if pname == "cornel_csv"
		config = CSVParserConfig(
			Dict(1=>:id, 2=>:author,
			     3=>:name, 4=>:publisher,
			     5=>:edition_year,
			     6=>:published_year,
			     8=>:documenttype),
			Dict(1=>false, 2=>true, 3=>true,
			     4=>true, 5=>false, 6=>false,
			     7=>false, 8=>true,
			     9=>true, 10=>false)
		)
		return (path::String)->parse_csv_cornel(path, config, delim='\t', header=true)
	else
		return (path::String)->nothing
	end
end



# Function that returns a corpus from a delimited file;
# the individual document metadata and text are filled according
# to the config::CSVParserConfig
function parse_csv_cornel(file::AbstractString, config::CSVParserConfig;
		   delim::Char = ',', header::Bool = true)

	# Pre-allocate
	vsd = Vector{StringDocument}()
	
	# Parse
	open(file, "r") do f
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
	end

	# create and post-process corpus
	crps = Corpus(vsd)
	prepare!(crps, TEXT_STRIP_FLAGS)

	# Update lexicon and inverse index
	update_lexicon!(crps)
	update_inverse_index!(crps)

	return crps
end
