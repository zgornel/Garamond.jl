module Garamond

VERSION >= v"0.6.0" && __precompile__(true)

	# Using section
	using Word2Vec, LightGraphs, NearestNeighbors, MLKernels

	# Import section

	# Export section
	export find_cluster_mean,
		get_cluster_matrix, 
		get_cluster_matrix!,
		find_close_clusters, 
		path

	# Includes
	include("utils.jl")

end # module
