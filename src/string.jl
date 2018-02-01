# Define base filtering functions
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

