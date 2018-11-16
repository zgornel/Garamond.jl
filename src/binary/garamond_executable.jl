###############################################################################
# File that is to be compiled with juliac.jl to obtain a Garamond binary blob #
###############################################################################
module GaramondExecutable

# Set variables
LOCAL_PACKAGES = expanduser("~/projects/")
push!(LOAD_PATH, LOCAL_PACKAGES)



using Garamond

###################################
# Main compilable module function #
###################################
Base.@ccallable function garamond_executable(ARGS::Vector{String})::Cint

    # Parse command line arguments
    args = get_commandline_arguments(ARGS)
    println("~ GARAMOND ~")
    ### wp = args["webpage"]
    ### dconf = args["data-config"]
    ### phttp = args["http-port"]

    ### # Start web server
    ### @assert !isempty(dconf) && isfile(dconf)
    ### start_http_server(wp, dconf, phttp)

    return 0
end

end # MainGaramond
