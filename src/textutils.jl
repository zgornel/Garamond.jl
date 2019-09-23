#################################################################
# Utils for interfacing with StringAnalysis.jl and Languages.jl #
#################################################################

# Converts a String to Languages.Language (using STR_TO_LANG)
convert(::Type{L}, lang::S) where {L<:Languages.Language, S<:AbstractString} = begin
    TypeLang = get(STR_TO_LANG, strip(lowercase(lang)), Languages.English)
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

"""
    meta2sv(metadata, fields=DEFAULT_METADATA_FIELDS_TO_INDEX)

Turns the `metadata::DocumentMetadata` object's `fields` into a vector of strings,
where the value of each field becomes an element in the resulting vector.
"""
function meta2sv(md::T, fields=DEFAULT_METADATA_FIELDS_TO_INDEX) where T<:DocumentMetadata
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

function meta2sv(md::Vector{T}, fields=DEFAULT_METADATA_FIELDS_TO_INDEX) where T<:DocumentMetadata
    map((meta)->meta2sv(meta, fields), md)
end



##########################################
# String utilities: constants, functions #
##########################################

# Overload ismatch to work matching any value within a vector
occursin(r::Regex, strings::T) where T<:AbstractArray{<:AbstractString} = 
    any(occursin(r, si) for si in sv);


# Overload lowercase function to work with vectors of strings
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
    StringAnalysis.prepare!(c, flags)
    filter!(doc->occursin(r"[a-zA-Z0-9]",text(doc)), documents(c))
    update_lexicon!(c)
    t = dtm(DocumentTermMatrix{Float32}(c))
    tf_idf!(t)
    # Page rank
    α = 0.85  # damping factor
    n = 100  # number of iterations
    ϵ = 1.0e-6  # convergence threhshold
    G = Graph(t' * t)
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
    build_corpus(documents, metadata_vector, doctype)

Builds a corpus of documents of type `doctype` using the data in `documents`
and metadata from `metadata_vector`.
"""
function build_corpus(documents::Vector{Vector{String}},
                      metadata_vector::Vector{DocumentMetadata},
                      ngram_complexity::Int)
    @assert length(documents) == length(metadata_vector)
    docs = Vector{StringDocument{String}}()
    @inbounds for (sentences, meta) in zip(documents, metadata_vector)
        lang_type = typeof(meta.language)
        if lang_type in SUPPORTED_LANGUAGES
            doc = StringDocument(join(sentences, " "))
            doc.metadata = meta
            push!(docs, doc)
        else
            @warn """Unsupported language $lang_type for document id=$(meta.id).
                     The document will be ignored."""
        end
    end
    crps = Corpus(docs)
    # Update lexicon, inverse index
    update_lexicon!(crps, ngram_complexity)
    update_inverse_index!(crps, ngram_complexity)
    return crps
end


"""
    query_preparation(query, flags, language)

Prepares the query for search (tokenization if the case), pre-processing.
"""
function query_preparation(query::AbstractString, flags::UInt32, language::Languages.Language)
    String.(tokenize(prepare(query, flags, language=language), method=DEFAULT_TOKENIZER))
end

function query_preparation(needles::Vector{String}, flags::UInt32, language::Languages.Language)
    # To minimize time, no pre-processing is done here.
    # The input is returned as is.
    return needles
end

function query_preparation(query, flags::UInt32, language::Languages.Language)
    throw(ArgumentError("Query pre-processing requires `String` or Vector{String} inputs."))
end
