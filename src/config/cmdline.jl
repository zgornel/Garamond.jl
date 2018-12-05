# Function that parses Garamond's server arguments
function get_server_commandline_arguments(args::Vector{String})
	s = ArgParseSettings()
	@add_arg_table s begin
        "--data-config", "-d"
            help = "data configuration file"
            action = :append_arg
        "--log-level"
            help = "logging level"
            default = "info"
        "--log", "-l"
            help = "logging stream"
            default = "stdout"
        "--socket", "-s"
            help = "UNIX socket for data communication"
            default = "/tmp/garamond/sockets/socket1"
	end
	
	return parse_args(args,s)
end
