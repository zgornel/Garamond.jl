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



# Parser for "csv_format_1"
function __parser_csv_format_1(filename::AbstractString,
                               config::Dict,
                               doc_type::Type{T}=DEFAULT_DOC_TYPE;
                               delim::Char = '|',
                               header::Bool = false) where T<:AbstractDocument
    # Initializations
    nlines = linecount(filename) - ifelse(header,1,0)
    documents = Vector{doc_type}(undef, nlines)
    documents_meta = Vector{doc_type}(undef, nlines)
    metafields = fieldnames(TextAnalysis.DocumentMetadata)
    # Load the file
    if header
        string_matrix, _ = readdlm(filename, delim, String, header=header)
    else
        string_matrix = readdlm(filename, delim, String, header=header)
    end
    # Select and sort the line fields which will be used as document text in the corpus
    mask = sort!([k for k in keys(config[:data]) if config[:data][k]])
    # Progressbar
    _nl = 10  # number of lines after wihich progress is updated
    _filename = split(filename,"/")[end]
    progressbar = Progress(div(nlines, _nl)+1,
                           desc="Parsing $_filename...",
                           color=:normal)
    @inbounds for il in 1:size(string_matrix,1)
        # Iterate and parse
        vline = strip.(view(string_matrix, il, :))
        iszero(mod(il, _nl)) && next!(progressbar)
        # Set document data
        doc = doc_type(join(vline[mask]," "))
        # Set document metadata
        metadata_fields = fieldnames(TextAnalysis.DocumentMetadata)
        for (column, metafield) in config[:metadata]
            local _language
            if metafield in metadata_fields
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
        doc_meta = metastring(doc, collect(v for v in DEFAULT_METADATA_FIELDS
                                           if v in metafields))
        documents_meta[il] = doc_type(doc_meta)
        # Create document vector
        documents[il] = doc
    end
    # Create and post-process document/document metadata corpora
    crps = Corpus(documents)
    crps_meta = Corpus(documents_meta)
    return crps, crps_meta
end
