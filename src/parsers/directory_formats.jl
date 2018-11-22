"""
    recursive_glob(pattern, path)

Globs recursively all the files matching the pattern, at the given path.
"""
function recursive_glob(pattern="*", path=".")
    contents = glob(pattern, path)
    mask_files = isfile.(contents)
    mask_dirs = isdir.(contents)
    files = contents[mask_files]
    directories = contents[mask_dirs]
    if all(mask_files)
    # Stop condition
        return contents
    elseif isempty(contents)
        # Empty directory, stop
        return String[]
    else
        # There are directories, recurse into them
        for dir in directories
            new_files = recursive_glob(pattern, dir)
            push!(files, new_files...)
        end
    end
    return files
end


# Parser for "directory_format_1"
# Logical to physical mapping:
#   - sentence -> sentence
#   - file -> document
#   - directory contents -> corpus
# The function returns a tuple (documents, metadata_vector):
#   Documents are a Vector{Vector{String}}:
#       - the String is the sentence
#       - the inner vector is for a the document: vector of sentences
#       - the outer vector is for the corpus: a vector of documents
#   The metadata vector is a Vector{DocumentMetadata}
# TODO(Corneliu): Add support for other files (so far only text files supported)
function __parser_directory_format_1(directory::AbstractString,
                                     config::Dict=Dict();  # not used
                                     globbing_pattern::String=DEFAULT_GLOBBING_PATTERN,
                                     build_summary::Bool=DEFAULT_BUILD_SUMMARY,
                                     summary_ns::Int=DEFAULT_SUMMARY_NS,
                                     show_progress::Bool=DEFAULT_SHOW_PROGRESS,
                                     kwargs...  # unused kw arguments (used in other parsers)
                                    ) where T<:AbstractDocument
    # Initializations
    files = recursive_glob(globbing_pattern, directory)
    n = length(files)
    n==0 && @error "No files found in $directory with glob: $globbing_pattern."
    # Initialize outputs
    documents = Vector{Vector{String}}(undef, n)
    metadata_vector = Vector{DocumentMetadata}(undef, n)
    metadata_fields = fieldnames(DocumentMetadata)
    # Progressbar
    progressbar = Progress(n,
                    desc="Parsing $(split(directory,"/")[end])...",
                    color=:normal)
    ################################################################
    # Any logic about how to process metadata, data should go into #
    # the `config`; for now it is not used.                        #
    ################################################################
    for (i, file) in enumerate(files)
        # Read data and split into sentences
        sentences = split_sentences(open(fid->read(fid, String), file))
        # Create summary if the case
        if build_summary
            # TODO(Corneliu): Optimize this bit for performance
            #                 i.e. investigate PageRank parameters
            sentences = summarize(sentences, ns=summary_ns, flags=SUMMARIZATION_FLAGS)
        end
        documents[i] = sentences
        # TODO(Corneliu) Add language support for supported languages
        # through language detection
        metadata_vector[i] = DocumentMetadata(Languages.English(),
                                "", "", "", "", "", "", "", "", "")
        # Add some real metadata
        setfield!(metadata_vector[i], :name, readuntil(file,"\n"))  # set name the first line
        setfield!(metadata_vector[i], :id, file)  # set id the filename
        # Update progressbar
        show_progress && next!(progressbar)
    end
    return documents, metadata_vector
end
