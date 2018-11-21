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



# Parser for "delimited_format_1"
# Logical to physical mapping:
#   - field -> sentence
#   - line (multiple fields) -> document
#   - file -> corpus
# The function returns a tuple (documents, metadata_vector):
#   Documents are a Vector{Vector{String}}:
#       - the String is the sentence
#       - the inner vector is for a the document: vector of sentences
#       - the outer vector is for the corpus: a vector of documents
#   The metadata vector is a Vector{StringAnalysis.DocumentMetadata}
function __parser_delimited_format_1(filename::AbstractString,
                                     config::Dict;
                                     header::Bool = false,
                                     delimiter::String=DEFAULT_DELIMITER,
                                     show_progress::Bool=DEFAULT_SHOW_PROGRESS,
                                     kwargs...  # unused kw arguments (used in other parsers)
                                    ) where T<:AbstractDocument
    # Initializations
    nlines = linecount(filename) - ifelse(header,1,0)
    nlines==0 && error("$filename contains no data lines.")
    # Select and sort the line fields which will be used as document text in the corpus
    fields_mask = sort!([k for k in keys(config[:data]) if config[:data][k]])
    # Read the file
    if header
        string_matrix, _ = readdlm(filename, delimiter[1], String, header=header)
    else
        string_matrix = readdlm(filename, delimiter[1], String, header=header)
    end
    # Progressbar
    _nl = 10  # number of lines after wihich progress is updated
    _filename = split(filename,"/")[end]
    progressbar = Progress(div(nlines, _nl)+1,
                           desc="Parsing $_filename...",
                           color=:normal)
    # Initialize outputs
    nlines = min(nlines, size(string_matrix,1))  # avoid newlines
    documents = Vector{Vector{String}}(undef, nlines)
    metadata_vector = Vector{StringAnalysis.DocumentMetadata}(undef, nlines)
    metadata_fields = fieldnames(StringAnalysis.DocumentMetadata)
    # Loop over loaded data and process data
    @inbounds for i in 1:size(string_matrix,1)
        # Iterate and parse
        vline = strip.(view(string_matrix, i, :))
        iszero(mod(i, _nl)) && show_progress && next!(progressbar)
        # Create document
        documents[i] = vline[fields_mask]
        metadata_vector[i] = StringAnalysis.DocumentMetadata(Languages.English(),
                                "", "", "", "", "", "", "", "", "")
        # Set parsed values for document metadata
        for (column, metafield) in config[:metadata]
            local _language
            if metafield in metadata_fields
                # Metadata field is to be parsed
                if metafield == :language
                    # Get Language object from string
                    _lang = lowercase(vline[column])
                    try
                        #_language = STR_TO_LANG[_lang]
                        # HACK, force Languages.English() as there is little
                        # reason to use other languages. Preprocessing fails
                        # as dictionaries are needed
                        # TODO(Corneliu): Add language support for supported languages.
                        _language = STR_TO_LANG["english"]
                    catch
                        @warn "Language $_lang not supported. Using default."
                        _language = Languages.English()
                    end
                    setfield!(metadata_vector[i], metafield, _language)
                else
                    # Non-language field
                    setfield!(metadata_vector[i], metafield, lowercase(vline[column]))
                end
            end
        end
    end
    return documents, metadata_vector
end
