module Garamond

VERSION >= v"0.6.0" && __precompile__(true)

	# Using section
	using Word2Vec, LightGraphs, NearestNeighbors, MLKernels
	using HttpServer, WebSockets, JSON
 
	# Import section
	import Base: show, ismatch, convert

	# Export section
	export  #HTTP server
		start_http_server,

		# Search related 
		ismatch,
		match_exactly_by_field,
		matcher,
		query_process, 

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
	include("server.jl")
	include("search.jl")
	include("data.jl")
	include("heuristics.jl")

end # module
