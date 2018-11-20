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
    # TODO: Implement logic similar to garamond.jl
    return 0
end

end # MainGaramond
