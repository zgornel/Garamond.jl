module Garamond

VERSION >= v"0.6.0" && __precompile__(true)

	# Using section
	using Word2Vec, LightGraphs, NearestNeighbors, MLKernels
	using HttpServer, WebSockets
 
	# Import section
	import Base: show

	# Export section
	export find_cluster_mean,
		get_cluster_matrix, 
		get_cluster_matrix!,
		find_close_clusters, 
		path, 
		start_http_server,
		AbstractItem, AbstractBook, Book,
		parse_books
		

	# Includes
	include("data.jl")
	include("heuristics.jl")
	include("search.jl")
	include("server.jl")

end # module
