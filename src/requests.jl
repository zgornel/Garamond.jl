"""
Standard deconstructed request corresponding to an error request.
"""
const ERRORED_REQUEST = ("request_error", "", 0, :nothing, :nothing, 0, "")


"""
    deconstruct_request(request)

Function that deconstructs a Garamond request received from a client into
individual search engine operations and search parameters.
"""
function deconstruct_request(request::String)
    try
        # Parse JSON request
        req = JSON.parse(request)
        # Read fields
        op = req["operation"]
        query = req["query"]
        max_matches = req["max_matches"]
        search_method = Symbol(req["search_method"])
        max_suggestions = req["max_suggestions"]
        what_to_return = req["what_to_return"]
        return op, query, max_matches, search_method,
               max_suggestions, what_to_return
    catch
        return ERRORED_REQUEST
    end

end


"""
    construct_response(srchers, results, what [; kwargs...])

Function that constructs a response for a Garamond client using
the search `results`, data from `srchers` and specifier `what`.
"""
function construct_response(srchers, results, what::String;
                            max_suggestions::Int=0, elapsed_time::Float64=0)
    buf = IOBuffer()
    if what == "json-index"
        # Write to buffer indices of the documents
        write(buf, JSON.json(results))
    elseif what == "json-data"
        # Write to buffer document metadata
        result_data = export_results_for_web(srchers, results,
                        max_suggestions, elapsed_time)
        write(buf, JSON.json(result_data))
    else
        @error "Unknown response type."  # should not reach this point
    end
    response = join(Char.(buf.data))
    return response
end


# Export results to be a format that can be converted into JSON for
# webpage viewing
# #TODO(Corneliu) Display suggestions as well, improve function
function export_results_for_web(srchers::S, results::T, max_suggestions::Int,
                                elapsed_time::Float64
                               ) where {S<:AbstractVector{<:Searcher},
                                        T<:AbstractVector{<:SearchResult}}
    # Count the total number of results
    if !isempty(results)
        nt = mapreduce(x->valength(x.query_matches), +, results)
    else
        nt = 0
    end

    no_matches(result::T) where T<:SearchResult =
        isempty(result, quety_matches for field in fieldnames(T))
    # This structure matches the one expencted
    # in the web clients search page
    r = Dict("etime"=>elapsed_time,
             "matches" => Dict{String, Vector{Tuple{Float64, Dict{String,String}}}}(),
             "n_matches" => nt,
             "n_corpora" => length(results),
             "n_corpora_match" =>
                mapreduce(r->!isempty(r.query_matches), +, results))
    for (i, _result) in enumerate(results)
        crps = srchers[i].corpus
        push!(r["matches"], _result.id.id => Vector{Dict{String,String}}())
        if !isempty(crps)
            for score in sort(collect(keys(_result.query_matches)), rev=true)
                for doc in (crps[i] for i in _result.query_matches[score])
                    dictdoc = convert(Dict, metadata(doc))
                    push!(r["matches"][_result.id.id], (score, dictdoc))
                end
            end
        end
    end
    suggestions = squash_suggestions(results, max_suggestions)
    return r
end
