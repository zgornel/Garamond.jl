# Function that parses Garamond's arguments
function get_commandline_arguments(args::Vector{String})
	s = ArgParseSettings()
	@add_arg_table s begin
		"--webpage", "-w"
			help = "the webpage to display"
			default = ""
		"--http-port", "-p"
			help = "use specified port for HTTP related communication"
			default = 9999
			arg_type = Int
		"--data", "-d"
			help = "data file to be used"
			default = ""
		"--data-port"
			help = "use specified port for TCP data communication"
			default = 9998
			arg_type = Int
		"--socket", "-s"
			help = "use specified UNIX socket for data communication"
			default = ""
		"--server-only", "-o"
			help = "start in server only mode (i.e. without the HTTP server)"
			action = :store_true
	end
	
	return parse_args(args,s)
end
