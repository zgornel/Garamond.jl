#######################
#       PARSERS       #
#######################

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
#   The metadata vector is a Vector{DocumentMetadata}
#
# Example of parser config:
# ------------------------
#   Dict("metadata"=> Dict(1=>"id",
#                          2=>"author",
#                          3=>"name",
#                          4=>"publisher",
#                          5=>"edition_year",
#                          6=>"published_year",
#                          7=>"language",
#                          8=>"note",
#                          9=>"location"),
#        "data"=> [2,3,8]
#       )
function __parser_delimited_format_1(filename::AbstractString,
                                     config::Dict;
                                     header::Bool = false,
                                     delimiter::String=DEFAULT_DELIMITER,
                                     language::String=DEFAULT_LANGUAGE_STR,
                                     show_progress::Bool=DEFAULT_SHOW_PROGRESS,
                                     kwargs...  # unused kw arguments (used in other parsers)
                                    ) where T<:AbstractDocument
    # Initializations
    filename = expanduser(filename)
    nlines = open(countlines, filename) - ifelse(header,1,0)
    nlines==0 && error("$filename contains no data lines.")
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
    # Read, sort and filter the line fields which
    # will be used as document text in the corpus
    data_fields = collect(config["data"])
    ncols = size(string_matrix, 2)
    filter!(col->col > 0 && col <= ncols, data_fields)
    # Filter metadata mappings
    metadata_fields = fieldnames(DocumentMetadata)
    config_meta = Dict(parse(Int, k) => Symbol(v)
                       for (k,v) in config["metadata"])
    filter!(p->p.first > 0 && p.first <= ncols, config_meta)
    filter!(p->p.second in metadata_fields, config_meta)
    # Initialize outputs
    nlines = min(nlines, size(string_matrix,1))  # avoid newlines
    documents = Vector{Vector{String}}(undef, nlines)
    metadata_vector = Vector{DocumentMetadata}(undef, nlines)
    # Loop over loaded data and process data
    @inbounds for i in 1:size(string_matrix,1)
        # Iterate and parse
        vline = strip.(view(string_matrix, i, :))
        iszero(mod(i, _nl)) && show_progress && next!(progressbar)
        # Create document
        documents[i] = vline[data_fields]
        # Language detection
        if language == "auto"
            lang = detect_language(join(vline, " "))  # detect from the whole data line
        else
            lang = get(STR_TO_LANG, language, DEFAULT_LANGUAGE)()  # instantiate as well
        end
        metadata_vector[i] = DocumentMetadata(lang, ("" for _ in 1:9)...)
        # Set parsed values for document metadata
        for (column, metafield) in config_meta
            # Metadata field is to be parsed
            field_data = lowercase(vline[column])
            if metafield == :language
                # Explicitly override language if a language field is present
                lang = get(STR_TO_LANG, field_data, DEFAULT_LANGUAGE)()
                setfield!(metadata_vector[i], metafield, lang)
            else
                # Non-language field
                setfield!(metadata_vector[i], metafield, field_data)
            end
        end
    end
    return documents, metadata_vector
end
