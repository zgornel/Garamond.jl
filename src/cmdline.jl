# Function that parses Garamond's arguments
function get_commandline_arguments(args::Vector{String})
	s = ArgParseSettings()
	@add_arg_table s begin
        "--data-config", "-d"
            help = "data configuration file"
            action = :append_arg
        "--engine-config", "-e"
            help = "search engine configuration file"
            default = ""
        "--verbose", "-v"
            help = "verbosity option"
            default = "Debug"
        "--socket", "-s"
            help = "user specified UNIX socket for data communication"
            default = "/tmp/garamond/sockets/socket1"
        "--query", "-q"
            help = "query the search engine if in client mode"
            default = ""
        "--client"
            help = "client mode"
            action = :store_true
        "--server"
            help = "server mode"
            action = :store_true
	end
	
	return parse_args(args,s)
end
