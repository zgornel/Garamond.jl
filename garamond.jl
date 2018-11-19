#!/bin/julia

##########################################################################
# File that is to be run with `julia run.jl` in order to start Garamond  #
##########################################################################
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
    # --
    data_config_paths = String.(args["data-config"])
    engine_config_path = String(args["engine-config"])
    verbosity = args["verbose"]
    socket = args["socket"]
    query = args["query"]
    is_client = args["client"]
    is_server = args["server"]

    # Logging
    if lowercase(verbosity) == "debug"
        logger = ConsoleLogger(stdout, Logging.Debug)
    elseif lowercase(verbosity) == "info"
        logger = ConsoleLogger(stdout, Logging.Info)
    elseif lowercase(verbosity) == "error"
        logger = ConsoleLogger(stdout, Logging.Error)
    else
        logger = ConsoleLogger(stdout, Logging.Info)
    end
    global_logger(logger)

    # Start FSM
    println("~ GARAMOND ~ $(Garamond.printable_version())\n")
    if is_server && !is_client
        Garamond.fsm(data_config_paths, socket, engine_config_path, verbosity)
    elseif is_client  # if both client and server set, client wins
        conn = connect(socket)
        if !isempty(query)
            Garamond.iosearch(conn, query)
        else
            @info "Empty query. Nothing to search ;)"
        end
        close(conn)
        return 0
    else
        @info "Use either '--server' of '--client' flags. Exiting."
        return 0
    end
end

main()

end # RunGaramond
