"""
    search_server(data_config_paths, io_port, search_server_ready)

Search server for Garamond. It is a finite-state-machine that
when called, creates the searchers i.e. search objects using the
`data_config_paths` and the proceeds to looping continuously
in order to:
 - update the searchers regularly (asynchronously);
 - receive requests from clients on the port `io_port`
 - call search and route responses asynchronouslt back
   to the clients through `io_port`

After the searchers are loaded, the search server sends a notification
using `search_server_ready` to any listening I/O servers.
"""
function search_server(data_config_paths, io_port, search_server_ready)
    # Load data
    srchers = load_searchers(data_config_paths)

    # Start updater
    update_channel = Channel{typeof(srchers)}(0)
    @async updater(srchers, channels=update_channel)

    # Notify waiting I/O servers
    @info "Searchers loaded. Notifying I/O servers..."
    notify(search_server_ready, true)

    # Start search server
    server = listen(Sockets.localhost, io_port)
    @info "Search server waiting for queries @inet-socket:$io_port..."

    # Main loop
    while true
        # Check and update searchers
        if isready(update_channel)
            srchers = take!(update_channel)
            @info "* Updated: $(length(srchers)) searchers."
        end

        # Start accepting requests and asynchronously
        # respond to them using the opened socket
        sock = accept(server)
        @async respond(srchers, sock)
    end
end


"""
    respond(srchers, socket)

Responds to search server requests received on `socket` using
the search data from `searchers`.
"""
function respond(srchers, socket)
    # Read and parse JSON request
    request = parse(SearchServerRequest, readline(socket))
    @debug "* Received: $request."

    t_init = time()
    if request.op == "search"
        ### Search ###
        results = search(srchers, request.query,
                         search_method=request.search_method,
                         max_matches=request.max_matches,
                         max_suggestions=request.max_suggestions,
                         custom_weights=request.custom_weights)

        query_time = time() - t_init
        @info "* Search: query='$(request.query)' completed in $query_time(s)."

        # Construct response for client
        corpora = select_corpora(srchers, results, request)
        response = construct_json_response(results, corpora,
                        max_suggestions=request.max_suggestions,
                        elapsed_time=query_time)

        # Write response to I/O server
        write(socket, response * RESPONSE_TERMINATOR)

    elseif request.op == "kill"
        ### Kill the search server ###
        @info "* Kill: Exiting in 1(s)..."
        write(socket, RESPONSE_TERMINATOR)
        sleep(1)
        exit()

    elseif request.op == "read-configs"
        ### Read and return data configurations ***
        @info "* Getting searcher data configuration(s)..."
        write(socket,
              read_searcher_configurations_json(srchers) * RESPONSE_TERMINATOR)

    elseif request.op == "request-error"
        @info "* Errored request: Ignoring..."
        write(socket, RESPONSE_TERMINATOR)

    else
        @info "* Unknown request: Ignoring..."
        write(socket, RESPONSE_TERMINATOR)
    end

    @debug "Response sent after $(time()-t_init)(s)."
end


"""
    select_corpora(srchers, results, request)

Returns an iterator through the data contained in the searchers
or `nothing` depending on the search request, searchers and
search results.
"""
function select_corpora(srchers, results, request)
    # Select the data (if any) that will be reuturned
    local corpora
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
    return corpora
end
