module Garamond

VERSION >= v"0.6.0" && __precompile__(true)

	# Using section
	using Word2Vec, LightGraphs, NearestNeighbors, MLKernels
	using HttpServer, WebSockets
 
	# Import section

	# Export section
	export find_cluster_mean,
		get_cluster_matrix, 
		get_cluster_matrix!,
		find_close_clusters, 
		path, 
		start_http_server 
		

	# Includes
	include("utils.jl")
	include("sockserver.jl")

end # module
