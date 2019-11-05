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

