###################################################
# Data Loading - related functions and structures #
###################################################
# Parsing flow:
#   1. Parse configuration file using `parse_corpora_configuration`
#   2. The resulting Vector{CorpusRef} is passed to `load_corpora`
#      (each CorpusRef contains the data filepath, corpus name etc.
#   3. Parse the data file, obtain Corpus and add to Corpora (`add_corpora!`)
"""
Define the csv parser configuration. It maps the fields from a delimited file
to document metadata fields and specifies whether a field is to be included
or not in the document text through the `data` field value.
For example:
    ParserConfig(Dict(1=>:id, 2=>:author),
                 Dict(1=>true, 2=>true))
    specifies to map the first column of the delimited file to the id field,
    the second to the author and to load both.
"""
mutable struct ParserConfig
    metadata::Dict{Int, Symbol}  # when parsed, the value used as metadata field
    data::Dict{Int, Bool}  # when parsing, the key column used for the index
end



# Parser configurations; the keys have to appear in the parsing configuration files;
# The name of the data parsing function is created from them using the formula:
# `:__parser_<key>` i.e. `:__parser_csv_format_1` corresponds to key `:csv_format_1`
PARSER_CONFIGS = Dict(
    :csv_format_1 => ParserConfig(
        Dict(1=>:id, 2=>:author, 3=>:name,
             4=>:publisher, 5=>:edition_year, 6=>:published_year,
             7=>:language,
             8=>:documenttype, 9=>:characteristics, 10=>:location),
        Dict(1=>false, 2=>true, 3=>true,
             4=>false, 5=>false, 6=>false,
             7=>false, 8=>false, 9=>false, 10=>false)
       )
)



"""
Function that creates corpus references i.e. CorpusRef,
using a Garamond corpora config file. The corpus reference
links a Corpus object to its file representation and is
used to load the corpus.
"""
function parse_corpora_configuration(filename::AbstractString)
    #######
    # Function that generated a parsing function from a parser configuration name
    # and header information (used in parsing the data configuration file for
    # generating a ParserConfig)
    function get_parsing_function(parser_config::Symbol; header::Bool=false)
        PREFIX = :__parser_
        # Construct basic parsing function from parser option value
        _function  = eval(Symbol(PREFIX, parser_config))
        # Get parser config
        _config = get(PARSER_CONFIGS, parser_config, nothing)
        _config isa Nothing && @error ":$config_name parser configuration not found!"
        # Build parsing function (a nice closure)
        function parsing_function(filename::String,
                                  id_type::Type{T}=DEFAULT_ID_TYPE,
                                  doc_type::Type{D}=DEFAULT_DOC_TYPE) where
                {T<:AbstractId, D<:AbstractDocument}
            return _function(filename,
                             _config,
                             doc_type,
                             delim='\t',
                             header=header)
        end
        return parsing_function
    end
    #######
    crefs = Vector{CorpusRef}()
    last_header = false
    last_parser = :indentity
    # Start parsing
    open(filename, "r") do f
        counter = 0
        for line in eachline(f)
            # Initialize temporary variables
            _line = strip(line)
            if startswith(_line, "#")
                # Comment
                continue
            elseif startswith(_line, "[")
                push!(crefs, CorpusRef(name=replace(line, r"(\[|\])"=>"")))
                counter+= 1
            elseif occursin("=", _line) && counter > 0
                # Property assignment (option = value)
                opt, val = strip.(split(_line, "="))
                if opt == "parser" && !isempty(val)
                    last_parser = Symbol(val)
                    crefs[counter].parser =
                        get_parsing_function(last_parser, header=last_header)
                elseif opt == "path" && !isempty(val)
                    crefs[counter].path = val
                elseif opt == "enabled" && !isempty(val)
                    crefs[counter].enabled = Bool(Meta.parse(val))
                elseif opt == "header" && !isempty(val)
                    last_header = Bool(Meta.parse(val))
                    crefs[counter].parser = get_parsing_function(
                        last_parser, header=last_header)
                else
                    @warn "Line \"$line\" in $(filename) is not valid. will skip"
                    continue
                end
            else
                # Un-parsable line (skip)
                continue
            end
        end
    end
    return crefs
end



#######################
#       PARSERS       #
#######################

# Function that gets the number of lines in a file
function linecount(filename::AbstractString)::Int
    @assert !Sys.iswindows() "wc does not work on Windows."
    @assert isfile(filename) "$filename does not exist."
    n = parse(Int, split(read(`wc -l $filename`, String))[1])
    return n
end



# Parser for "csv_format-1"
function __parser_csv_format_1(filename::AbstractString,
                               config::ParserConfig,
                               doc_type::Type{T}=DEFAULT_DOC_TYPE;
                               delim::Char = ',',
                               header::Bool = false) where T<:AbstractDocument
    # Initializations
    nlines = linecount(filename) - ifelse(header,1,0)
    documents = Vector{doc_type}(undef, nlines)
    documents_meta = Vector{doc_type}(undef, nlines)
    metafields = fieldnames(TextAnalysis.DocumentMetadata)
    # Parse
    open(filename, "r") do f
        # Select and sort the line fields which will be used as
        # document text in the corpus
        mask = sort!([k for k in keys(config.data) if config.data[k]])
        # Progressbar
        _nl = 10  # number of lines after wihich progress is updated
        _filename = split(filename,"/")[end]
        progressbar = Progress(div(nlines, _nl)+1,
                               desc="Parsing $_filename...",
                               color=:normal)
        # Iterate and parse
        lc = 0  # line counter
        header && readline(f)  # skip header
        for line in eachline(f)
            vline = String.(strip.(split(line, delim, keepempty=false)))
            lc += 1
            iszero(mod(lc, _nl)) && next!(progressbar)
            # Set document data
            doc = doc_type(join(vline[mask]," "))
            # Set document metadata
            for (column, metafield) in config.metadata
                local _language
                if metafield in fieldnames(typeof(doc.metadata))
                    if metafield == :language
                        _lang = lowercase(vline[column])
                        try
                            #_language = STR_TO_LANG[_lang]
                            # HACK, force Languages.English() as there is little
                            # reason to use other languages. Preprocessing fails
                            # as dictionaries are needed
                            _language = STR_TO_LANG["english"]
                        catch
                            @warn "Language $_lang not supported. Using default."
                            _language = Languages.English()
                        end
                        setfield!(doc.metadata, metafield, _language)
                    else
                        setfield!(doc.metadata, metafield, lowercase(vline[column]))
                    end
                end
            end
            # Create metadata document vector
            doc_meta = metastring(doc, collect(v for v in values(config.metadata)
                                               if v in metafields))
            documents_meta[lc] = doc_type(doc_meta)
            # Create document vector
            documents[lc] = doc
        end
    end
    # Create and post-process document/document metadata corpora
    crps = Corpus(documents)
    crps_meta = Corpus(documents_meta)
    for (c, flags) in zip((crps, crps_meta),
                          (TEXT_STRIP_FLAGS, METADATA_STRIP_FLAGS))
        prepare!(c, flags)       # preprocess
        #update_lexicon!(c)       # create lexicon
        update_inverse_index!(c) # create inverse index
    end
    return Corpus(crps.documents), inverse_index(crps), inverse_index(crps_meta)
end
