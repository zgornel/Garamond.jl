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

