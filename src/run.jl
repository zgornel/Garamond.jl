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
	web_page = args["webpage"]
	data_file = args["data"]
	http_port = args["http-port"]
	
	# Start web server
	start_http_server(web_page, data_file, http_port)
	
	return 0
end

garamond_julia()

end # RunGaramond

