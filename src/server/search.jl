"""
    search_server(data_config_path, io_port, search_server_ready)

Search server for Garamond. It is a finite-state-machine that
when called, creates the searchers i.e. search objects using the
`data_config_path` and the proceeds to looping continuously
in order to:
 - update the searchers regularly (asynchronously);
 - receive requests from clients on the port `io_port`
 - call search and route responses asynchronouslt back
   to the clients through `io_port`

After the searchers are loaded, the search server sends a notification
using `search_server_ready` to any listening I/O servers.
"""
function search_server(data_config_path, io_port, search_server_ready)

    # Build search environment
    env = build_search_env(data_config_path)

    # Start updater
    up_in_channel = Channel{String}(0)  # input (searcher id)
    up_out_channel = Channel{typeof(env.searchers)}(0)  # output (updated searchers)
    channels = (up_in_channel, up_out_channel)
    @async updater(env, channels)

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
            env.searchers = take!(up_out_channel)
        end

        # Start accepting requests and asynchronously
        # respond to them using the opened socket
        sock = accept(server)
        @async respond(env, sock, counter, channels)
    end
end


"""
    respond(env, socket, counter, channels)

Responds to search server requests received on `socket` using
the search data from `searchers`. The requests are counted
through the variable `counter`.
"""
function respond(env, socket, counter, channels)
    # Channels for updating
    up_in_channel, up_out_channel = channels

    # Read and parse an outside request
    request = parse(InternalRequest, readline(socket))
    counter.+= 1
    @debug "* Received [#$(counter[1])]: $request."

    timer_start = time()
    if request.operation === :search
        ### Search ###
        results = search(env, request)
        etime = time() - timer_start
        response = build_response(env.dbdata, request, results; id_key=env.id_key, elapsed_time=etime)
        write(socket, response * RESPONSE_TERMINATOR)
        @info "• Search [#$(counter[1])]: query='$(request.query)' completed in $etime(s)."

    elseif request.operation === :recommend
        ### Recommend ###
        recommendations = recommend(env, request)
        etime = time() - timer_start
        response = build_response(env.dbdata, request, recommendations; id_key=env.id_key, elapsed_time=etime)
        write(socket, response * RESPONSE_TERMINATOR)
        @info "• Recommendation [#$(counter[1])]: completed in $etime(s)."

    elseif request.operation === :rank
        ranked = rank(env, request)  #::Vector{SearchResult}
        etime = time() - timer_start
        response = build_response(env.dbdata, request, ranked; id_key=env.id_key, elapsed_time=etime)
        @info "• Rank [#$(counter[1])]: completed in $etime(s)."
        write(socket, response * RESPONSE_TERMINATOR)

    elseif request.operation === :kill
        ### Kill the search server ###
        @info "• Kill [#$(counter[1])]: Exiting in 1(s)..."
        write(socket, RESPONSE_TERMINATOR)
        sleep(1)
        exit()

    elseif request.operation === :read_configs
        ### Read and return data configurations ###
        @info "• Get configuration(s) [#$(counter[1])]."
        write(socket, read_configuration_to_json(env) * RESPONSE_TERMINATOR)

    elseif request.operation === :update
        ### Read and return data configurations ###
        @info "• Update searcher(s) [#$(counter[1])]."
        # The request query contains the string id of the updated searcher
        if !isready(up_in_channel)
            put!(up_in_channel, request.query)  # the take! is in the search server
        else
            @warn "Update request ignored: update in progress..."
        end
        write(socket, RESPONSE_TERMINATOR)  # send response asynchronously

    elseif request.operation === :error
        @info "• Errored request [#$(counter[1])]: Ignoring..."
        write(socket, RESPONSE_TERMINATOR)

    else
        @info "• Unknown request [#$(counter[1])]: Ignoring..."
        write(socket, RESPONSE_TERMINATOR)
    end

    close(socket)
    @debug "* Response [#$(counter[1])]: done after $(time()-timer_start)(s)."
end


"""
    build_response(dbdata, request, results, [; kwargs...])

Builds a response for an engine client using the data, request and results.
"""
function build_response(dbdata,
                        request,
                        results;
                        id_key=DEFAULT_DB_ID_KEY,
                        elapsed_time=-1.0)
    if !isempty(results)
        n_total_results = mapreduce(x->length(x.query_matches), +, results)
    else
        n_total_results = 0
    end

    response_results = Dict{String, Vector{Dict{Symbol, Any}}}()
    return_fields = Tuple(intersect!(unique!([request.return_fields..., id_key]),
                                     colnames(dbdata)))
    for result in results
        dict_vector = []
        indices, scores = map(i->getindex.(result.query_matches, i), [2, 1])
        dataresult = sort(rows(filter(in(indices), dbdata, select=id_key), return_fields),
                          by=row->getproperty(row, id_key))
        for (entry, score) in sort(collect(zip(dataresult, scores[sortperm(indices)])),
                                   by=zipped->zipped[2], rev=true)
            dict_entry = Dict{Symbol, Any}(pairs(entry))
            push!(dict_entry, :score => score)
            push!(dict_vector, dict_entry)
        end
        push!(response_results, result.id.value => dict_vector)
    end
    response = Dict("elapsed_time"=>elapsed_time,
                    "results" => response_results,
                    "n_total_results" => n_total_results,
                    "n_searchers" => length(results),
                    "n_searchers_w_results" => mapreduce(r->!isempty(r.query_matches), +, results),
                    "suggestions" => squash_suggestions(results, request.max_suggestions))
    return JSON.json(response)
 end
