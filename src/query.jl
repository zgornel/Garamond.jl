# Functionality related to the processing of the query
"""
    process_query(query [;doc_type=TextAnalysis.StringDocument])

Processes a document `query` and returns a vector of strings
containing the pre-processed and stemmed tokens.
Through `doc_type` the type of document in which the query can
be wrapped (for processing) can be specified, in case the query
is not already a `TextAnalysis.AbstractDocument`.
"""
process_query(query::AbstractString;
              prepare::Bool=false,
              stem::Bool=false) = begin
    # Note: preparation and stemming slow by hundreds of μs the search.
    prepare && prepare!(query, QUERY_STRIP_FLAGS)
    stem && stem!(query)
    return extract_tokens(query)
end

process_query(query::V;
              doc_type::Type{T}=TextAnalysis.StringDocument
             ) where {T<:TextAnalysis.AbstractDocument,
                      V<:AbstractVector{<:AbstractString}} = begin
    process_query(join(query," "))
end
