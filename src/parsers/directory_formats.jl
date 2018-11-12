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
# TODO(Corneliu): Add support for other files (so far only text files supported)
function __parser_directory_format_1(directory::AbstractString,
                                     config::Dict,  # not used
                                     doc_type::Type{T}=DEFAULT_DOC_TYPE;
                                     globbing_pattern::String=DEFAULT_GLOBBING_PATTERN,
                                     build_summary::Bool=DEFAULT_BUILD_SUMMARY,
                                     summary_ns::Int=DEFAULT_SUMMARY_NS,
                                     kwargs...  # unused kw arguments (used in other parsers)
                                    ) where T<:AbstractDocument
    # Initializations
    files = recursive_glob(globbing_pattern, directory)
    n = length(files)
    n==0 && @error "No files found in $directory with glob: $globbing_pattern."
    documents = Vector{doc_type}(undef, n)
    documents_meta = Vector{doc_type}(undef, n)
    metadata_fields = fieldnames(TextAnalysis.DocumentMetadata)
    progressbar = Progress(n,
                           desc="Parsing $(split(directory,"/")[end])...",
                           color=:normal)
    ################################################################
    # Any logic about how to process metadata, data should go into #
    # the `config`; for now it is not used.                        #
    ################################################################
    for (i, file) in enumerate(files)
        # Read data
        data = open(fid->read(fid, String), file)
        # Create summary if the case
        if build_summary
            # TODO(Corneliu): Optimize this bit for performance
            #                 i.e. investigate PageRank parameters
            data = summarize(data, ns=summary_ns, flags=SUMMARIZATION_FLAGS)
        end
        doc = doc_type(data)
        # Spoof metadata
        # Note: this bit is necessary in order not to pollute document
        #       information with the default (crappy) metadata values
        #       i.e. "Unknown Time", "Unknown Title" etc.
        for metafield in metadata_fields
            if metafield == :language
                _language = STR_TO_LANG["english"]
                setfield!(doc.metadata, metafield, _language)
            else
                setfield!(doc.metadata, metafield, "")
            end
        end
        # Add some real metadata
        setfield!(doc.metadata, :name, readuntil(file,"\n"))  # set name the first line
        setfield!(doc.metadata, :id, file)  # set id the filename
        # Create metadata document vector
        doc_meta = metastring(doc, collect(v for v in DEFAULT_METADATA_FIELDS
                                           if v in metadata_fields))
        documents_meta[i] = doc_type(doc_meta)
        # Create document vector
        documents[i] = doc
        next!(progressbar)
    end
    # Create metadata document vector
    # Create and post-process document/document metadata corpora
    crps = Corpus(documents)
    crps_meta = Corpus(documents_meta)
    return crps, crps_meta
end
