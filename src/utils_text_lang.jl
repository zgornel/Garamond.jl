#################################################################
# Utils for interfacing with StringAnalysis.jl and Languages.jl #
#################################################################

# Converts a String to Languages.Language (using STR_TO_LANG)
convert(::Type{L}, lang::S) where {L<:Languages.Language, S<:AbstractString} =
    get(STR_TO_LANG, strip(lower(lang)), Languages.English())

# Converts Languages.Language to String (using LANG_TO_STR)
convert(::Type{S}, lang::L) where {L<:Languages.Language, S<:AbstractString} =
	get(LANG_TO_STR, lang, "unknown")

# Convert a StringAnalysis metadata structure to a Dict
convert(::Type{Dict}, md::DocumentMetadata) =
    Dict{String,String}((String(field) => getfield(md, field))
                         for field in fieldnames(DocumentMetadata))


# Turn the document metadata into a vector of strings
function meta2sv(md::T, fields=fieldnames(T)) where T<:DocumentMetadata
    msv = ["" for _ in 1:length(fields)]
    for (i, field) in enumerate(fields)
        if field in fieldnames(T)
            if field != :language
                msv[i] = getfield(md, field)
            else
                msv[i] = LANG_TO_STR[getfield(md, field)]
            end
        end
    end
    filter!(!isempty, msv)
    return msv
end



##########################################
# String utilities: constants, functions #
##########################################

# Overload ismatch to work matching any value within a vector
occursin(r::Regex, strings::T) where T<:AbstractArray{<:AbstractString} = 
    any(occursin(r, si) for si in sv);


# Overload lowervase function to work with vectors of strings
lowercase(v::T) where T<:AbstractArray{S} where S<:AbstractString =
    Base.lowercase.(v)



"""
    detect_language(text)

Detects the language of a piece of text.
"""
# TODO(Corneliu) Find a use for this or remove
function detect_language(text::AbstractString)
    detector = LanguageDetector()
    l::Language = detector(text)[1]  # returns (language, script, confidence)
    return l
end



"""
    summarize(sentences [;ns=1, flags=SUMMARIZATION_FLAGS]

Build a summary of the text's `sentences`. The resulting summary will be
a `ns` sentence document; each sentence is pre-procesed using the
`flags` option.
"""
function summarize(sentences::Vector{S};
                   ns::Int=1,
                   flags::UInt32=SUMMARIZATION_FLAGS
                  ) where S<:AbstractString
    # Get document term matrix
    s = StringDocument.(sentences)
    c = Corpus(s)
    prepare!(c, flags)
    update_lexicon!(c)
    t = tf_idf(dtm(c))
    # Page rank
    α = 0.85  # damping factor
    n = 100  # number of iterations
    ϵ = 1.0e-6  # convergence threhshold
    G = Graph(t * t')
    try
        p = pagerank(G, α, n, ϵ)
        # Sort sentences and return
        text_summary = sentences[sort(sortperm(p, rev=true)[1:min(ns, length(p))])]
        return text_summary
    catch
        @warn "Summarization failed during TextRank. No summarization done."
        return sentences
    end
end



"""
    build_corpus(documents, doctype, metadata_vector)

Builds a corpus of documents of type `doctype` using the data in `documents`
and metadata from `metadata_vector`.

Note: No preprocessing is performed at this step, it is assumed that the data
      has already been preprocessed and is ready to be searched in.
"""
function build_corpus(documents::Vector{Vector{S}},
                      doctype::Type{T},
                      metadata_vector::Vector{DocumentMetadata}
                     ) where {S<:AbstractString, T<:AbstractDocument}
    @assert length(documents) == length(metadata_vector)
    n = length(documents)
    v = Vector{T}(undef, n)
    @inbounds for i in 1:n
        v[i] = T(join(documents[i]," "))
        v[i].metadata = metadata_vector[i]
    end
    return Corpus(v)
end


"""
    prepare_query(query, flags)

Prepares the query for search (tokenization if the case), pre-processing.
"""
prepare_query(query::AbstractString, flags::UInt32) = begin
    String.(tokenize_fast(prepare(query, flags)))
end

prepare_query(query::Vector{<:AbstractString}, flags::UInt32) = begin
    return vcat((prepare_query(q, flags) for q in query)...)
end
