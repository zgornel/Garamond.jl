###############################################################
# Utils for interfacing with TextAnalysis.jl and Languages.jl #
###############################################################

# Printer for TextAnalysis metadata
titleize(str::AbstractString) = begin
    join(map(uppercasefirst, strip.(split(str, "."))), ". ","")
end


show(io::IO, md::TextAnalysis.DocumentMetadata) = begin
    printstyled(io, "$(md.id)-[", color=:light_black)
    printstyled(io, "\"$(titleize(md.name))\"",
                    " by $(titlecase(md.author)),",
                    " $(md.edition_year)",
                    " ($(md.published_year))]")
end


# Converts a String to Languages.Language (using STR_TO_LANG)
convert(::Type{L}, lang::S) where {L<:Languages.Language, S<:AbstractString} =
    get(STR_TO_LANG, strip(lower(lang)), Languages.English())

# Converts Languages.Language to String (using LANG_TO_STR)
convert(::Type{S}, lang::L) where {L<:Languages.Language, S<:AbstractString} =
	get(LANG_TO_STR, lang, "unknown")

# Convert a TextAnalysis metadata structure to a Dict
convert(::Type{Dict}, md::TextAnalysis.DocumentMetadata) =
    Dict{String,String}((String(field) => getfield(md, field))
                         for field in fieldnames(TextAnalysis.DocumentMetadata))


# Medatadata getter for documents
metadata(document::D) where {D<:AbstractDocument} =
    document.metadata


metadata(crps::C) where {C<:TextAnalysis.Corpus} =
    [doc.metadata for doc in crps]


# Turn the document metadata into a string
function metastring(md::TextAnalysis.DocumentMetadata,
                    fields::Vector{Symbol}=DEFAULT_METADATA_FIELDS)
	join([getfield(md, field) for field in fields]," ")
end


function metastring(document::D,
                    fields::Vector{Symbol}=DEFAULT_METADATA_FIELDS) where
        {D<: AbstractDocument}
	metastring(metadata(document), fields)
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


function prepare!(input_string::AbstractString, flags::UInt32)
	_sd = StringDocument(Unicode.normalize(input_string,
                                           decompose=true,
                                           compat=true,
                                           casefold=true,
                                           stripmark=true,
                                           stripignore=true,
                                           stripcc=true))
	prepare!(_sd, flags)
	return filter(x::AbstractString -> length(x) > 1,
	              String.(split(text(_sd))))
end



"""
    extract_tokens(doc)

Tokenizes various types of documents. Works for `AbstractString`,
Vector{AbstractString} and `TextAnalysis.jl` documents.
"""
extract_tokens(doc::NGramDocument) = String.(collect(keys(doc.ngrams)))
extract_tokens(doc::StringDocument) = String.(tokenize_for_conceptnet(doc.text))
extract_tokens(doc::AbstractString) = String.(tokenize_for_conceptnet(doc))
extract_tokens(doc::Vector{S} where S<:AbstractString) = String.(doc)



### # Useful regular expressions
### replace.(select(tt2,2),r"([A-Z]\s|[A-Z]\.\s)","")  # replace middle initial 
### replace.(select(tt2,2),r"[\s]+$","")  # replace end spaces 
### 
### # Define base filtering functions
### 
### remove_punctuation(s) = filter(x->!ispunct(x), s)
### 
### remove_singlechars(s) = filter(x->length(x) > 1, s)
### 
### split_space_tab(s) = split(s, r"(\s|\t|-)")
### 
### normalizer(s) = normalize_string(s, decompose=true, compat=true, casefold=true,
### 				    stripmark=true, stripignore=true)
### 
### function searchquery_preprocess(s)
### String.(
###     remove_singlechars(
### 	split_space_tab(
### 		remove_punctuation(
### 			normalizer(s)
### 		)
### 	)
### ))	
### end

"""
    detect_language(text)

Detects the language of a piece of text.
"""
function detect_language(text::AbstractString)
    detector = LanguageDetector()
    l::Language = detector(text)[1]  # returns (language, script, confidence)
    return l
end



"""
    summarize(text [;ns=1, flags=SUMMARIZATION_FLAGS]

Build a summary of the `text`. The resulting summary will be
a `ns` sentence document; each sentence is pre-procesed using the
`flags` option.
"""
function summarize(text::AbstractString;
                   ns::Int=1,
                   flags::UInt32=SUMMARIZATION_FLAGS,
                   language::Language=detect_language(text))
    # Tokenize
    sentences = TextAnalysis.sentence_tokenize(language, text)  # language is not used
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
        return join(text_summary)  # return a string
    catch
        @warn "Summarization failed while computing TextRank. Returning full document."
        return text
    end
end
