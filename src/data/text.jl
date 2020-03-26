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
    s = prepare.(sentences, flags)
    filter!(d->occursin(r"[a-zA-Z0-9]", d), s)
    t = dtm(DocumentTermMatrix{Float32}(s))
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
Post-processes a string to fit a certain length, adding … if necessary
at the end of its choped represenation.
"""
function chop_to_length(input, len)
     input = replace(input, "\n" => "")
     idxs = collect(eachindex(input))
     _idx = findlast(Base.:<=(len), idxs)
     if _idx == nothing
         _len=0
     else
         _len = idxs[findlast(Base.:<=(len), idxs)]
     end
     length(input) > len ? input[1:_len] * "…"  : input
end
