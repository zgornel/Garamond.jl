#################################################################
# Utils for interfacing with StringAnalysis.jl and Languages.jl #
#################################################################

# Converts a String to Languages.Language (using STR_TO_LANG)
convert(::Type{L}, lang::S) where {L<:Languages.Language, S<:AbstractString} = begin
    TypeLang = get(STR_TO_LANG, strip(lower(lang)), Languages.English)
    return TypeLang()
end

# Converts Languages.Language to String (using LANG_TO_STR)
convert(::Type{S}, lang::Type{L}) where {L<:Languages.Language, S<:AbstractString} =
    get(LANG_TO_STR, lang, string(L))

convert(::Type{S}, lang::L) where {L<:Languages.Language, S<:AbstractString} =
    convert(S, L)

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
                msv[i] = LANG_TO_STR[typeof(getfield(md, field))]
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
    detect_language(text [; default=DEFAULT_LANGUAGE])

Detects the language of a piece of `text`. Returns a language of
type `Languages.Language`. If the text is empty of the confidence
is low, return the `default` language.
"""
function detect_language(text::AbstractString; default=DEFAULT_LANGUAGE)
    isempty(text) && return default
    detector = LanguageDetector()
    l, _, c = detector(text)  # returns (language, script, confidence)
    if c < 0.15
        return default()
    else
        return l
    end
end



"""
    summarize(sentences [;ns=1, flags=DEFAULT_SUMMARIZATION_STRIP_FLAGS])

Build a summary of the text's `sentences`. The resulting summary will be
a `ns` sentence document; each sentence is pre-procesed using the
`flags` option.
"""
function summarize(sentences::Vector{S};
                   ns::Int=1,
                   flags::UInt32=DEFAULT_SUMMARIZATION_STRIP_FLAGS
                  ) where S<:AbstractString
    # Get document term matrix
    s = StringDocument{String}.(sentences)
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
    docs = Vector{T}()
    @inbounds for (sentences, meta) in zip(documents, metadata_vector)
        lang_type = typeof(meta.language)
        if lang_type in SUPPORTED_LANGUAGES
            doc = T(join(sentences," "))
            doc.metadata = meta
            push!(docs, doc)
        else
            @warn """Unsupported language $lang_type for document id=$(meta.id).
                     The document will be ignored."""
        end
    end
    return Corpus(docs)
end


"""
    prepare_query(query, flags)

Prepares the query for search (tokenization if the case), pre-processing.
"""
prepare_query(query::AbstractString, flags::UInt32) = begin
    String.(tokenize_fast(prepare(query, flags)))
end

prepare_query(needles::Vector{String}, flags::UInt32) = begin
    # To minimize time, no pre-processing is done here.
    # The input is returned as is.
    return needles
end

prepare_query(query, flags::UInt32) = begin
    @error "Query pre-processing requires `String` or Vector{String} inputs."
end
