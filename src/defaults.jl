# Seatch defaults
const DEFAULT_SEARCH_TYPE = :index  # can be :index or :metadata
const DEFAULT_SEARCH_METHOD = :exact  #can be :exact or :regex
const DEFAULT_MAX_MATCHES = 1_000  # maximum number of matches that can be retrned
const DEFAULT_MAX_SUGGESTIONS = 1  # maximum number of overall suggestions
const DEFAULT_MAX_CORPUS_SUGGESTIONS = 1  # maximum number of suggestions for each corpus
const MAX_EDIT_DISTANCE = 2  # maximum edit distance for which to return suggestions

# Search tree constants
const DEFAULT_METADATA_FIELDS = [:author, :name]  # Default metadata fields for search
const DEFAULT_HEURISTIC = :levenshtein  #can be :levenshtein or :fuzzy
const HEURISTIC_TO_DISTANCE = Dict(  # heuristic to distance object mapping
    :levenshtein => StringDistances.Levenshtein(),
    :dameraulevenshtein => StringDistances.DamerauLevenshtein(),
    :hamming => StringDistances.Hamming(),
    :jaro => StringDistances.Jaro())

# Text pre-processing flags (for the prepare! function)
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

# String <=>Language dictionaries and
# Languages.Languages <=> String conversion functions
const LANG_TO_STR = Dict((v=>k) for (k,v) in STR_TO_LANG)
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
