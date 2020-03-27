#######################################################################################
# DATA Configuration: these are used to provide default values in case options in the #
# data configuration files are missing.                                               #
#######################################################################################
const DEFAULT_BUILD_SUMMARY = false  # whether to summarize text before indexing
const DEFAULT_SUMMARY_NS = 1  # Default number of sentences for a summary
const DEFAULT_STEM_WORDS = false  # whether to stem words or not

# Search
const DEFAULT_VECTORS = :bm25  # can be :count, :tf, :tfidf, :bm25, :word2vec, :glove or :conceptnet
const DEFAULT_VECTORS_TRANSFORM = :none  # can be :none, :lsa or :rp
const DEFAULT_VECTORS_DIMENSION = 1  # can be any positive Int
const DEFAULT_VECTORS_ELTYPE = Float32
const DEFAULT_SEARCH_INDEX = :hnsw  # can be :naive, :brutetree, :kdtree or :hnsw
const DEFAULT_EMBEDDINGS_KIND = :binary  # can be :binary or :text
const DEFAULT_DOC2VEC_METHOD = :boe  # can be :boe, :sif, :borep or :cpmean
const DEFAULT_SEARCH_METHOD = :exact  #can be :exact or :regex
const DEFAULT_HEURISTIC  = nothing #  i.e. :hamming, :levenshtein (nothing for no suggestions)
const DEFAULT_BM25_KAPPA = 2  # default value for BM25 κ parameter
const DEFAULT_BM25_BETA = 0.75  # default value for BM25 β parameter
const DEFAULT_SIF_ALPHA = 0.01  # default value for α parameter of the SIF doc2vec method
const DEFAULT_BOREP_DIMENSION = 1024  # default BOREP embedder output dimensionality
const DEFAULT_BOREP_POOLING_FUNCTION = :sum  # pooling function for BOREP embeddera i.e. :sum, :max
const DEFAULT_DISC_NGRAM = 2  # DisC embedder n-gram parameter
const DEFAULT_SCORE_ALPHA = 0.5  # default value of the α parameter of the score transformation
const DEFAULT_OOV_POLICY = :none  # values are :none, :large_vector
const DEFAULT_OOV_VAL = 1000  # default value for OOV vectors
# Results
const DEFAULT_RESULT_AGGREGATION_STRATEGY = :mean  # can be :minimum, :maximum, :mean, :median, :product

# Text stripping flags
const DEFAULT_TEXT_STRIP_FLAGS = strip_case | strip_punctuation | strip_articles |
                                 strip_prepositions | strip_whitespace |
                                 strip_corrupt_utf8 | strip_accents
const DEFAULT_QUERY_STRIP_FLAGS = strip_case | strip_punctuation | strip_articles |
                                  strip_prepositions | strip_whitespace |
                                  strip_corrupt_utf8 | strip_accents

# Caching options
const DEFAULT_CACHE_DIRECTORY = nothing
const DEFAULT_CACHE_COMPRESSION = "none"

# Query parsing
const DEFAULT_QUERY_PARSING_SEPARATOR=":"
const DEFAULT_QUERY_GENERATION_FIELDS=Symbol[]

# SearchEnv-related options
const DEFAULT_DB_ID_KEY = :garamond_linear_id
const DEFAULT_DATA_LOADER_NAME = :noop_loader
const DEFAULT_DATA_SAMPLER_NAME = :noop_sampler
const DEFAULT_RANKER_NAME = :noop_ranker
const DEFAULT_RECOMMENDER_NAME = :noop_recommender
const DEFAULT_INPUT_PARSER_NAME = :noop_input_parser


#################
# SEARCH ENGINE #
#################
# TODO(Corneliu): Check here if any of them can also be data configuration options
#                 i.e. max matches, edit distance, document type
const DEFAULT_MAX_MATCHES = 1  # maximum number of matches that can be retrned
const DEFAULT_RESPONSE_SIZE = DEFAULT_MAX_MATCHES  # maximum number of matches that are returned for a request
const DEFAULT_RESPONSE_PAGE = 1  # which response page i.e. batch of response_size results to display
const DEFAULT_SORT_FIELDS = Symbol[]
const DEFAULT_SORT_REVERSE = false
const DEFAULT_MAX_SUGGESTIONS = 0  # maximum number of overall suggestions
const DEFAULT_CUSTOM_WEIGHTS = Dict{Symbol,Any}()  # default custom searcher weights
const DEFAULT_PDFTOTEXT_PROGRAM = "/usr/bin/pdftotext"  # program to convert PDFs to text
const DEFAULT_MAX_EDIT_DISTANCE = 2  # maximum edit distance for which to return suggestions

# DYNAMIC Configuration: These defaults can be through run-time options of the
#                        Garamond CLI client/server utilities
const DEFAULT_LOG_LEVEL = Logging.Info
const DEFAULT_LOGGER = ConsoleLogger

# STATIC Configuration: These constants cannot be overwritten
const DEFAULT_GARAMONDRC_FILE = expanduser("~/.garamondrc.jl")
const DEFAULT_ENVOP_SLEEP_INTERVAL = 10  # 10 seconds to wait between environment operation commands
const HEURISTIC_TO_DISTANCE = Dict(  # heuristic to distance object mapping
    :levenshtein => StringDistances.Levenshtein(),
    :dameraulevenshtein => StringDistances.DamerauLevenshtein(),
    :hamming => StringDistances.Hamming(),
    :jaro => StringDistances.Jaro())
const DEFAULT_DISTANCE = HEURISTIC_TO_DISTANCE[:jaro]  # default distance
const DEFAULT_PARSER_CONFIG = nothing
const DEFAULT_INDEXABLE_FIELDS = nothing
const DEFAULT_EMBEDDABLE_FIELDS = nothing
# Dictionaries for String <=>Languages.Language / Languages.Languages <=> String
# conversion
const STR_TO_LANG = Dict("english"=>Languages.English,
                         "french"=>Languages.French,
                         "german"=>Languages.German,
                         "italian"=>Languages.Italian,
                         "finnish"=>Languages.Finnish,
                         "dutch"=>Languages.Dutch,
                         "portuguese"=>Languages.Portuguese,
                         "spanish"=>Languages.Spanish,
                         "russian"=>Languages.Russian,
                         "serbian"=>Languages.Serbian,# and Languages.Croatian
                         "swedish"=>Languages.Swedish,
                         "czech"=>Languages.Czech,
                         "polish"=>Languages.Polish,
                         "bulgarian"=>Languages.Bulgarian,
                         "esperanto"=>Languages.Esperanto,
                         "hungarian"=>Languages.Hungarian,
                         "greek"=>Languages.Greek,
                         "norwegian"=>Languages.Nynorsk,
                         "slovene"=>Languages.Slovene,
                         "romanian"=>Languages.Romanian,
                         "vietnamese"=>Languages.Vietnamese,
                         "latvian"=>Languages.Latvian,
                         "turkish"=>Languages.Turkish,
                         "danish"=>Languages.Danish,
                         "arabic"=>Languages.Arabic,
                         "persian"=>Languages.Persian,
                         "korean"=>Languages.Korean,
                         "thai"=>Languages.Thai,
                         "georgian"=>Languages.Georgian,
                         "hebrew"=>Languages.Hebrew,
                         "telugu"=>Languages.Telugu,
                         "estonian"=>Languages.Estonian,
                         "hindi"=>Languages.Hindi,
                         "lithuanian"=>Languages.Lithuanian,
                         "ukrainian"=>Languages.Ukrainian,
                         "belarusian"=>Languages.Belarusian,
                         "swahili"=>Languages.Swahili,
                         "urdu"=>Languages.Urdu,
                         "kurdish"=>Languages.Kurdish,
                         "azerbaijani"=>Languages.Azerbaijani,
                         "tamil"=>Languages.Tamil
                        )

const LANG_TO_STR = Dict((v=>k) for (k,v) in STR_TO_LANG)
const SUPPORTED_LANGUAGES = [Languages.English,
                             Languages.German,
                             Languages.Romanian,
                             Languages.French,
                             Languages.Italian,
                             Languages.Dutch]
const DEFAULT_LANGUAGE = Languages.English
const DEFAULT_LANGUAGE_STR=LANG_TO_STR[DEFAULT_LANGUAGE]
const DEFAULT_TOKENIZER = :stringanalysis
const DEFAULT_NGRAM_COMPLEXITY = 1

##########################
# OTHER USEFUL CONSTANTS #
##########################
const DEFAULT_VERSION = "0.2.0-dev"
const DEFAULT_VERSION_DATE = "2020-02-07"
const DEFAULT_VERSION_COMMIT = "b8fa82f*"
