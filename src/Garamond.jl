module Garamond

VERSION >= v"0.6.0" && __precompile__(true)

	# Using section
	using Word2Vec, LightGraphs, NearestNeighbors, MLKernels	# - for word discovery
	using HttpServer, WebSockets, JSON				# - for HTTP/WebSocket/JSON communication with the http server
	using ArgParse							# - for command line argument parsing

	# Import section
	import Base: show, ismatch, convert, lowercase

	# Export section
	export  #HTTP server
		start_http_server,

		# Search related 
		ismatch,
		match_exactly_by_field,
		matcher,
		query_process, 

		# Command line (application) related
		get_commandline_arguments,

		# Data related
		AbstractItem, AbstractBook, Book,
		parse_books,

		# Word embedddings
		find_cluster_mean,
		get_cluster_matrix, 
		get_cluster_matrix!,
		find_close_clusters, 
		path 
		

	# Includes
	include("data.jl")
	include("server.jl")
	include("search.jl")
	include("cmdline.jl")
	include("heuristics.jl")

end # module
