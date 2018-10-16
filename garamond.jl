#!/bin/julia

##########################################################################
# File that is to be run with `julia run.jl` in order to start Garamond  #
##########################################################################
module RunGaramond

using Pkg
Pkg.activate(@__DIR__)
using Garamond

########################
# Main module function #
########################
function garamond_julia()

    # Parse command line arguments
    args = get_commandline_arguments(ARGS)
    println("~ GARAMOND ~")

    ### wp = args["webpage"]
    ### dconf = args["data-config"]
    ### phttp = args["http-port"]
    ###
    ### # Start web server
    ### @assert !isempty(dconf) && isfile(dconf)
    ### start_http_server(wp, dconf, phttp)

    return 0
end

garamond_julia()

end # RunGaramond
