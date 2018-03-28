##########################################################################
# File that is to be run with `julia run.jl` in order to start Garamond  #
##########################################################################
module RunGaramond

# Set variables
LOCAL_PACKAGES = expanduser("~/projects/")
push!(LOAD_PATH, LOCAL_PACKAGES)



using Garamond

########################
# Main module function #
########################
function garamond_julia()
	
	# Parse command line arguments
	args = get_commandline_arguments(ARGS)
	
	wp = args["webpage"]
	dconf = args["data-config"]
	phttp = args["http-port"]
	
	# Start web server
	@assert !isempty(dconf) && isfile(dconf)
	start_http_server(wp, dconf, phttp)

	return 0
end

garamond_julia()

end # RunGaramond
