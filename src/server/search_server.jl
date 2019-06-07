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
    up_in_channel = Channel{String}(0)  # input (searcher id)
    up_out_channel = Channel{typeof(srchers)}(0)  # output (updated searchers)
    channels = (up_in_channel, up_out_channel)
    @async updater(srchers, channels...)

    # Notify waiting I/O servers
    @info "Searchers loaded. Notifying I/O servers..."
    notify(search_server_ready, true)

    # Start search server
    ipaddr = Sockets.localhost
    server = listen(ipaddr, io_port)
    @info "SEARCH server online @$ipaddr:$io_port..."

    # Main loop
    counter = [0]  # vector so the value is mutable
    while true
        # Check and update searchers
        if isready(up_out_channel)
            srchers = take!(up_out_channel)
        end

        # Start accepting requests and asynchronously
        # respond to them using the opened socket
        sock = accept(server)
        @async respond(srchers, sock, counter, channels)
    end
end


"""
    respond(srchers, socket, counter, channels)

Responds to search server requests received on `socket` using
the search data from `searchers`. The requests are counted
through the variable `counter`.
"""
function respond(srchers, socket, counter, channels)
    # Channels for updating
    up_in_channel, up_out_channel = channels

    # Read and parse JSON request
    request = parse(SearchServerRequest, readline(socket))
    counter.+= 1
    @debug "* Received [#$(counter[1])]: $request."

    t_init = time()
    if request.op == "search"
        ### Search ###
        results = search(srchers, request.query,
                         search_method=request.search_method,
                         max_matches=request.max_matches,
                         max_suggestions=request.max_suggestions,
                         custom_weights=request.custom_weights)

        query_time = time() - t_init
        @info "* Search [#$(counter[1])]: query='$(request.query)' completed in $query_time(s)."

        # Construct response for client
        corpora = select_corpora(srchers, results, request)
        response = construct_json_response(results, corpora,
                        max_suggestions=request.max_suggestions,
                        elapsed_time=query_time)

        # Write response to I/O server
        write(socket, response * RESPONSE_TERMINATOR)

    elseif request.op == "kill"
        ### Kill the search server ###
        @info "* Kill [#$(counter[1])]: Exiting in 1(s)..."
        write(socket, RESPONSE_TERMINATOR)
        sleep(1)
        exit()

    elseif request.op == "read-configs"
        ### Read and return data configurations ###
        @info "* Get configuration(s) [#$(counter[1])]."
        write(socket,
              read_searcher_configurations_json(srchers) * RESPONSE_TERMINATOR)

    elseif request.op == "update"
        ### Read and return data configurations ###
        @info "* Update searcher(s) [#$(counter[1])]."
        # The request query contains the string id
        # of the updated searcher
        if !isready(up_in_channel)
            put!(up_in_channel, request.query)  # the take! is in the search server
        else
            @warn "Update request ignored: update in progress..."
        end
        write(socket, RESPONSE_TERMINATOR)  # send response asynchronously

    elseif request.op == "request-error"
        @info "* Errored request [#$(counter[1])]: Ignoring..."
        write(socket, RESPONSE_TERMINATOR)

    else
        @info "* Unknown request [#$(counter[1])]: Ignoring..."
        write(socket, RESPONSE_TERMINATOR)
    end

    @debug "Response [#$(counter[1])]: done after $(time()-t_init)(s)."
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
