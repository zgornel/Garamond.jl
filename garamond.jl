#!/bin/julia

################################################
# Garamond script for client/server operations #
################################################
module RunGaramond

using Pkg
Pkg.activate(@__DIR__)
using Garamond
using Sockets
using Logging

########################
# Main module function #
########################
function main()

    # Parse command line arguments
    args = Garamond.get_commandline_arguments(ARGS)
    # Get the argument values
    data_config_paths = String.(args["data-config"])
    engine_config_path = String(args["engine-config"])
    log_level = args["log-level"]
    logging_stream = args["log"]
    socket = args["socket"]
    query = args["query"]
    is_client = get(args, "client", false)
    is_server = get(args, "server", false)
    # Logging
    logger = Garamond.build_logger(logging_stream, log_level)
    global_logger(logger)
    # Start Garamond in either server or client mode
    @debug "~ GARAMOND ~ $(Garamond.printable_version())\n"
    if is_server && !is_client
        # Server
        ########
        Garamond.fsm(data_config_paths, socket, engine_config_path, log_level)
    elseif !is_server && is_client
        # Client
        ########
        conn = connect(socket)
        if !isempty(query)
            Garamond.iosearch(conn, query)
        else
            ###
            # Do nothing, there is nothing to search
            ###
        end
        close(conn)
        return 0
    else
        @error "Use either '--server' of '--client' flags. Exiting."
        return 0
    end
end


# Start main Garamond function
main()

end # RunGaramond
