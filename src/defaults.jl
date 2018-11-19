#######################################################################################
# DATA Configuration: these are used to provide default values in case options in the #
# data configuration files are missing.                                               #
#######################################################################################
const DEFAULT_SEARCH = :classic  # Search approach
const DEFAULT_BUILD_SUMMARY = false  # whether to summarize text before indexing
const DEFAULT_SUMMARY_NS = 1  # Default number of sentences for a summary
const DEFAULT_STEM_WORDS = false  # whether to stem words or not
# Classic seatch defaults
const DEFAULT_COUNT_TYPE = :tfidf  # can be :tf or :tfidf
const DEFAULT_SEARCH_TYPE = :data  # can be :data or :metadata
const DEFAULT_SEARCH_METHOD = :exact  #can be :exact or :regex
const DEFAULT_HEURISTIC = :hamming
const DEFAULT_COUNT_ELEMENT_TYPE = Float32  # used in classic search
# Semantic search related
const DEFAULT_EMBEDDING_METHOD = :bow  # can be :bow or :arora
const DEFAULT_EMBEDDINGS_TYPE = :conceptnet  # can be :word2vec or :conceptnet
const DEFAULT_EMBEDDING_SEARCH_MODEL = :naive  # can be :naive, :kdtree or :hnsw
const DEFAULT_EMBEDDING_ELEMENT_TYPE = :Float32  # can be :Float32, :Float64
const DEFAULT_WORD2VEC_FILETYPE = :binary  # can be :binary or :text
# Various document parsing constants
const DEFAULT_PARSER = :no_parse
const DEFAULT_GLOBBING_PATTERN = "*"  # Can be any regexp-like pattern
const DEFAULT_DELIMITER = "|"  # For delimited files only (i.e. document is a line/record)
const DEFAULT_SHOW_PROGRESS = true  # Show progress while loading files (useful lor longer operations)
const DEFAULT_KEEP_DATA = true  # whether to keep the actual document data, metadata



##############################################################
# SEARCH ENGINE configuration: the constants here are used   #
# throughout the code and do not correspond to file-options. #
##############################################################
# TODO(corneliu): Check here if any of them can also be data configuration options
#  i.e. max matches, exit distance, document type
const DEFAULT_DOCUMENT_TYPE = TextAnalysis.NGramDocument  # default document object type
const DEFAULT_MAX_MATCHES = 1_000  # maximum number of matches that can be retrned
const DEFAULT_MAX_SUGGESTIONS = 1  # maximum number of overall suggestions
const DEFAULT_MAX_CORPUS_SUGGESTIONS = 1  # maximum number of suggestions for each corpus
const MAX_EDIT_DISTANCE = 2  # maximum edit distance for which to return suggestions
const HEURISTIC_TO_DISTANCE = Dict(  # heuristic to distance object mapping
    :levenshtein => StringDistances.Levenshtein(),
    :dameraulevenshtein => StringDistances.DamerauLevenshtein(),
    :hamming => StringDistances.Hamming(),
    :jaro => StringDistances.Jaro())
const DEFAULT_DISTANCE = HEURISTIC_TO_DISTANCE[DEFAULT_HEURISTIC]  # default distance
const DEFAULT_METADATA_FIELDS = [:author, :name, :note]  # Default metadata fields for search

# Text pre-processing flags (for the prepare! function)
const TEXT_STRIP_FLAGS = strip_case |
                         strip_punctuation |
                         strip_articles |
                         strip_non_letters |
                         strip_prepositions |
                         strip_whitespace |
                         strip_corrupt_utf8

const QUERY_STRIP_FLAGS = strip_case |
                          strip_punctuation |
                          strip_articles |
                          strip_non_letters |
                          strip_prepositions |
                          strip_whitespace |
                          strip_corrupt_utf8

const METADATA_STRIP_FLAGS = strip_case |
                             strip_punctuation |
                             strip_articles |
                             strip_prepositions |
                             strip_whitespace |
                             strip_corrupt_utf8

const SUMMARIZATION_FLAGS = strip_corrupt_utf8 |
                            strip_case |
                            strip_stopwords |
                            strip_non_letters

# Dictionaries for String <=>Languages.Language / Languages.Languages <=> String
# conversion
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

# Parser configurations; the keys of this dictionary have to appear in the
# parsing configuration files.
const PARSER_CONFIGS = Dict(
    :delimited_format_1 => Dict(
        :metadata=> Dict(1=>:id, 2=>:author, 3=>:name,
                         4=>:publisher, 5=>:edition_year,
                         6=>:published_year, 7=>:language,
                         8=>:note, 9=>:location),
        :data=> Dict(1=>false, 2=>true, 3=>true,
                     4=>false, 5=>false, 6=>false,
                     7=>false, 8=>true, 9=>false)),
    :directory_format_1 => Dict()
)
