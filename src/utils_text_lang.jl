###############################################################
# Utils for interfacing with TextAnalysis.jl and Languages.jl #
###############################################################

# Printer for TextAnalysis metadata
show(io::IO, md::TextAnalysis.DocumentMetadata) = begin
    printstyled(io,"$(md.id)-[",color=:light_black)
    printstyled(io,"\"$(md.name)\" by $(md.author), ",
                "$(md.edition_year) ($(md.published_year))]")
end



# String <=>Language dictionaries and
# Languages.Languages <=> String conversion functions
const STR_TO_LANG = Dict("english"=>Languages.English(),
                         "french"=>Languages.French(),
                         "german"=>Languages.German(),
                         "italian"=>Languages.Italian(),
                         "finnish"=>Languages.Finnish(),
                         "dutch"=>Languages.Dutch(),
                         "afrikaans"=>Languages.Dutch(),
                         "portuguese"=>Languages.Portuguese(),
                         "spanish"=>Languages.Spanish(),
                         "russian"=>Languages.Russian(),
                         "serbian"=>Languages.Serbian(),# and Languages.Croatian()
                         "swedish"=>Languages.Swedish(),
                         "czech"=>Languages.Czech(),
                         "polish"=>Languages.Polish(),
                         "bulgarian"=>Languages.Bulgarian(),
                         "esperanto"=>Languages.Esperanto(),
                         "hungarian"=>Languages.Hungarian(),
                         "greek"=>Languages.Greek(),
                         "norwegian"=>Languages.Nynorsk(),
                         "slovene"=>Languages.Slovene(),
                         "romanian"=>Languages.Romanian(),
                         "vietnamese"=>Languages.Vietnamese(),
                         "latvian"=>Languages.Latvian(),
                         "turkish"=>Languages.Turkish(),
                         "danish"=>Languages.Danish(),
                         "arabic"=>Languages.Arabic(),
                         "persian"=>Languages.Persian(),
                         "korean"=>Languages.Korean(),
                         "thai"=>Languages.Thai(),
                         "georgian"=>Languages.Georgian(),
                         "hebrew"=>Languages.Hebrew(),
                         "telugu"=>Languages.Telugu(),
                         "estonian"=>Languages.Estonian(),
                         "hindi"=>Languages.Hindi(),
                         "lithuanian"=>Languages.Lithuanian(),
                         "ukrainian"=>Languages.Ukrainian(),
                         "belarusian"=>Languages.Belarusian(),
                         "swahili"=>Languages.Swahili(),
                         "urdu"=>Languages.Urdu(),
                         "kurdish"=>Languages.Kurdish(),
                         "azerbaijani"=>Languages.Azerbaijani(),
                         "tamil"=>Languages.Tamil()
                        )

const LANG_TO_STR = Dict((v=>k) for (k,v) in STR_TO_LANG)



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

# Converts a TextAnalysis.DocumentMetadata to a Vector{TextAnalysisMetadata}
# (used by MultiDict{T}([...]) in search.jl)
convert(::Type{Vector{T}}, metadata::T) where {T<:TextAnalysis.DocumentMetadata}=
    T[metadata] 


# Medatadata getter for documents
metadata(document::D) where {D<:TextAnalysis.AbstractDocument} =
    document.metadata

metadata(crps::C) where {C<:TextAnalysis.Corpus} =
    [doc.metadata for doc in crps]



# Turn the document metadata into a string
function metastring(md::TextAnalysis.DocumentMetadata,
                    fields::Vector{Symbol}=[:author, :name, :publisher])
	join([getfield(md, field) for field in fields]," ")
end

function metastring(document::T,
                    fields::Vector{Symbol}=[:author, :name, :publisher]) where
        {T<: TextAnalysis.AbstractDocument}
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


const TEXT_STRIP_FLAGS = strip_case +
                         strip_numbers +
                         strip_punctuation +
			             strip_articles +
                         strip_non_letters +
                         strip_stopwords +
			             strip_prepositions +
                         strip_whitespace +
                         strip_corrupt_utf8

const QUERY_STRIP_FLAGS = strip_non_letters +
                          strip_punctuation +
                          strip_whitespace +
                          strip_corrupt_utf8

const METADATA_STRIP_FLAGS = strip_punctuation +
                             strip_whitespace +
                             strip_case

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




#####################################################
# String/Search utilities: fuzzy matching functions #
#####################################################

function matchinds(needle, haystack; acronym = false)
    chars = collect(needle)
    is = Int[]
    lastc = '\0'
    for (i, char) in enumerate(haystack)
        isempty(chars) && break
        while chars[1] == ' ' popfirst!(chars) end # skip spaces
        if lowercase(char) == lowercase(chars[1]) && (!acronym || !isletter(lastc))
            push!(is, i)
            popfirst!(chars)
        end
        lastc = char
    end
    return is
end



longer(x, y) = length(x) ≥ length(y) ? (x, true) : (y, false)

bestmatch(needle, haystack) =
    longer(matchinds(needle, haystack, acronym = true),
           matchinds(needle, haystack))

avgdistance(xs) = isempty(xs) ? 0 : (xs[end] - xs[1] - length(xs)+1)/length(xs)

function fuzzyscore(needle, haystack)
    score = 0.
    is, acro = bestmatch(needle, haystack)
    score += (acro ? 2 : 1)*length(is) # Matched characters
    score -= 2(length(needle)-length(is)) # Missing characters
    !acro && (score -= avgdistance(is)/10) # Contiguous
    !isempty(is) && (score -= mean(is)/100) # Closer to beginning
    return score
end

# Sort candidates by their Fuzzy distance with respect to a search term 
function fuzzysort(search, candidates; κ::Int=1)
    scores = pmap(cand -> (fuzzyscore(search, cand),
                           -levenshtein(search, cand)), candidates)
    (candidates[sortperm(scores)] |> reverse)[1:κ]
end



# Levenshtein Distance
function levenshtein(s1, s2)
    a, b = collect(s1), collect(s2)
    m = length(a)
    n = length(b)
    d = zeros(Int, m+1, n+1)

    d[1:m+1, 1] = 0:m
    d[1, 1:n+1] = 0:n

    for i = 1:m, j = 1:n
        d[i+1,j+1] = min(d[i  , j+1] + 1,
                         d[i+1, j  ] + 1,
                         d[i  , j  ] + (a[i] != b[j]))
    end
	return d[m+1, n+1]
end

# Sort candidates by their Levenshtein distance with respect to a search term 
function levsort(search, candidates; κ::Int = 1)
    scores = map(cand -> (levenshtein(search, cand),
                          -fuzzyscore(search, cand)), candidates)
    candidates = candidates[sortperm(scores)]
    return candidates[1:κ]
end
