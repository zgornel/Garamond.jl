###################################################
# Data Loading - related functions and structures #
###################################################
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
    metadata::Dict{Int, Symbol}
    data::Dict{Int, Bool}
end



# Parser configurations
PARSER_CONFIGS = Dict(
    :csv_format_1 => ParserConfig(
        Dict(1=>:id, 2=>:author, 3=>:name, 4=>:publisher, 5=>:edition_year, 6=>:published_year, 8=>:documenttype),
        Dict(1=>false, 2=>true, 3=>true, 4=>true, 5=>true, 6=>false, 7=>false, 8=>true, 9=>true, 10=>true)
       )
)



"""
Function that creates corpus references i.e. CorpusRef,
using a Garamond data config file. The corpus reference
links a Corpus object to its file representation and is
used when loading the corpus.
"""
function generate_corpus_references(filename::AbstractString)
    #######
    # Function that generated a parsing function from a parser configuration name
    # and header information (used in parsing the data configuration file for
    # generating a ParserConfig)
    function get_parsing_function(parser_config::Symbol; header::Bool=false)
        PREFIX = :__parser_
        _function  = eval(Symbol(PREFIX, parser_config))
        _config = get(PARSER_CONFIGS, parser_config, nothing)
        _config isa Nothing && @error ":$config_name parser configuration not found!"
        return (filename::String)->_function(filename, _config, delim='\t', header=header)
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
            elseif occursin("=", _line)
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

function __parser_csv_format_1(filename::AbstractString,
                               config::ParserConfig,
                               doctype::Type{T}=NGramDocument;
                               delim::Char = ',',
                               header::Bool = false) where
        {T<:TextAnalysis.AbstractDocument}
    # Pre-allocate
    documents = Vector{doctype}()
    # Parse
    open(filename, "r") do f
        # Select and sort the line fields which will be used as
        # document text in the corpus
        mask = sort!([k for k in keys(config.data) if config.data[k]])
        # Iterate and parse
        header && readline(f)  # skip header
        for line in eachline(f)
            vline = String.(strip.(split(line, delim, keepempty=false)))
            sd = doctype(join(vline[mask]," "))		# Set document data
            for (column, metafield) in config.metadata		# Set document metadata
                setfield!(sd.metadata, metafield, vline[column])
            end
            language!(sd, Languages.English())
            push!(documents, sd)
        end
    end
    # Create and post-process corpus
    crps = Corpus(documents)
    prepare!(crps, TEXT_STRIP_FLAGS)
    # Update lexicon and inverse index
    update_lexicon!(crps)
    update_inverse_index!(crps)
    return crps
end
