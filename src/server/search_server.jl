"""
    search_server(data_config_paths, io_channel, search_server_ready)

Search server for Garamond. It is a finite-state-machine that
when called, creates the searchers i.e. search objects using the
`data_config_paths` and the proceeds to looping continuously
in order to:
    • update the searchers regularly (asynchronously);
    • receive requests from clients on the I/O channel `io_channel`
    • call search and route responses back to the clients through `io_channel`

After the searchers are loaded, the search server sends a notification
using `search_server_ready` to any listening I/O servers.
"""
function search_server(data_config_paths, io_channel, search_server_ready)
    # Load data
    srchers = load_searchers(data_config_paths)

    # Start updater
    srchers_channel = Channel{typeof(srchers)}(0)
    @async updater(srchers, channels=srchers_channel)

    # Notify waiting I/O servers
    @info "Searchers loaded. Notifying I/O servers..."
    notify(search_server_ready, true)

    # Main loop
    while true
        if isready(srchers_channel)
            srchers = take!(srchers_channel)
            @info "* Updated: $(length(srchers)) searchers."
        else
            # Read and deconstruct request
            request = deconstruct_request(take!(io_channel))
            @debug "* Received: $request."
            if request.op == "search"
                ### Search ###

                t_init = time()
                # Get search results
                results = search(srchers, request.query,
                                 search_method=request.search_method,
                                 max_matches=request.max_matches,
                                 max_suggestions=request.max_suggestions)
                t_finish = time()

                elapsed_time = t_finish - t_init
                @info "* Search: query='$(request.query)' completed in $elapsed_time(s)."

                # Select the data (if any) that will be reuturned
                if request.what_to_return == "json-index"
                    corpora = nothing
                elseif request.what_to_return == "json-data"
                    idx_corpora = Int[]
                    for result in results
                        for (idx, srcher) in enumerate(srchers)
                            if result.id == srcher.config.id_aggregation ||
                                    result.id == srcher.config.id
                                push!(idx_corpora, idx)
                                break
                            end
                        end
                    end
                    corpora = (srchers[idx].corpus for idx in idx_corpora)
                    if length(corpora) == 0
                        @warn "No corpora data from which to return results."
                    end
                else
                    @warn "Unknown return option \"$(request.what_to_return)\", "*
                          "defaulting to \"json-index\"..."
                    corpora = nothing
                end

                # Construct response for client
                response = construct_response(results, corpora,
                                max_suggestions=request.max_suggestions,
                                elapsed_time=elapsed_time)
                # Write response to I/O server
                put!(io_channel, response)

            elseif request.op == "kill"
                ### Kill the search server ###
                @info "* Kill: Exiting in 1(s)..."
                put!(io_channel, "")
                sleep(1)
                exit()

            elseif request.op == "read_configs"
                ### Read and return data configurations ***
                @info "* Getting searcher data configuration(s)..."
                put!(io_channel, read_searcher_configurations_json(srchers))

            elseif request.op == "request_error"
                @info "* Errored request: Ignoring..."
                put!(io_channel, "")

            else
                @info "* Unknown request: Ignoring..."
                put!(io_channel, "")
            end
        end
    end
end
