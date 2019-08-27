#######################
#       PARSERS       #
#######################

function __parser_json(filename::AbstractString,
                       config=Dict;
                       language::String=DEFAULT_LANGUAGE_STR,
                       show_progress::Bool=DEFAULT_SHOW_PROGRESS,
                       kwargs...  # unused kw arguments (used in other parsers)
                      )
    # Initializations
    filename = expanduser(filename)
    # Read the file
    data = JSON.parse(read(filename, String))
    ndocs = length(data)
    # Progressbar
    _nl = 10  # number of lines after wihich progress is updated
    _filename = split(filename,"/")[end]
    progressbar = Progress(div(ndocs, _nl)+1, desc="Parsing $_filename...")
    # Initialize outputs
    documents = Vector{Vector{String}}(undef, ndocs)
    metadata_vector = Vector{DocumentMetadata}(undef, ndocs)
    # Loop over loaded data and process data
    @inbounds for (i, datapoint) in enumerate(data)
        # Update progress bar
        iszero(mod(i, _nl)) && show_progress && next!(progressbar)
        # Create document
        documents[i] = [_to_string(get(datapoint, field, ""))
                        for field in config["data"]]
        # Create metadata
        metadata_vector[i] = DocumentMetadata()
        config_meta = Dict(k => Symbol(v) for (k,v) in config["metadata"])
        setfield!(metadata_vector[i], :language,
                  get(STR_TO_LANG, language, DEFAULT_LANGUAGE)())
        for (field, metafield) in config_meta
            setfield!(metadata_vector[i], metafield,
                      _to_string(get(datapoint, field, "")))
        end
    end
    return documents, metadata_vector
end


# Function that transforms any array into a concatenation
# of its string-ified elements
_to_string(data::AbstractVector) = join(string.(data), " ")

_to_string(data::AbstractString) = data  # make sure it works on strings
