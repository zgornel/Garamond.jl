# Useful regular expressions
# - replace middle initial replace.(select(tt2,2),r"([A-Z]\s|[A-Z]\.\s)","")
# - replace end spaces replace.(select(tt2,2),r"[\s]+$","")

# Define base filtering functions
#=
remove_punctuation(s) = filter(x->!ispunct(x), s)

remove_singlechars(s) = filter(x->length(x) > 1, s)

split_space_tab(s) = split(s, r"(\s|\t|-)")

normalizer(s) = normalize_string(s, decompose=true, compat=true, casefold=true,
				    stripmark=true, stripignore=true)

function searchquery_preprocess(s)
String.(
    remove_singlechars(
	split_space_tab(
		remove_punctuation(
			normalizer(s)
		)
	)
))	
end
=#

const TEXT_STRIP_FLAGS = strip_case
			+ strip_numbers
			+ strip_punctuation
			+ strip_articles
			+ strip_non_letters
			+ strip_stopwords
			+ strip_prepositions
			+ strip_whitespace

const QUERY_STRIP_FLAGS = strip_non_letters
			 + strip_punctuation
			 + strip_whitespace

function prepare!(s::AbstractString, flags::UInt32)
	tmp_sd = StringDocument(normalize_string(s,
					  decompose=true,
					  compat=true,
					  casefold=true,
					  stripmark=true,
					  stripignore=true,
					  stripcc=true))
	prepare!(tmp_sd, flags)
	return filter(x::AbstractString -> length(x) > 1,
	              String.(split(text(tmp_sd)))
		      )
end
