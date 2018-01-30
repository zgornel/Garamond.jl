###############################################################################
# File that is to be compiled with juliac.jl to obtain a Garamond binary blob #
###############################################################################
module MainGaramond

# Set variables
LOCAL_PACKAGES = expanduser("~/projects/")
push!(LOAD_PATH, LOCAL_PACKAGES)



using Garamond

###################################
# Main compilable module function #
###################################
Base.@ccallable function garamondmain(ARGS::Vector{String})::Cint
	
	# Parse command line arguments
	args = get_commandline_arguments(ARGS)
	web_page = args["webpage"]
	data_file = args["data"]
	http_port = args["http-port"]
	
	# Start web server
	start_http_server(web_page, data_file, http_port)
	
	return 0
end

end # MainGaramond
