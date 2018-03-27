module Garamond

VERSION >= v"0.6.0" && __precompile__(true)

	# Using section
	using TextAnalysis, Languages					# - for index creation
	using Word2Vec, LightGraphs, NearestNeighbors, MLKernels	# - for word discovery
	using HttpServer, WebSockets, JSON				# - for HTTP/WebSocket/JSON communication with the http server
	using ArgParse							# - for command line argument parsing
	using DataStructures: Set
	# Import section
	import Base: show, keys, values, contains, convert, lowercase, search
	import TextAnalysis:prepare!, update_lexicon!, update_inverse_index!

	# Export section
	export  #HTTP server
		start_http_server,
		
		# String processing
		TEXT_STRIP_FLAGS,
		QUERY_STRIP_FLAGS,
		prepare!,

		# Search related 
		contains,
		fuzzysort,
		levsort,
		search,
		search_metadata, 
		search_index,
		search_heuristically,

		# Command line (application) related
		get_commandline_arguments,

		# Corpora related
		AbstractCorpora, 
		CorpusRef, 
		Corpora,
		keys,
		values,
		names,
		update_lexicon!,
		update_reverse_index!,
		metadata, metastring, dict, 

		# Parsing
		parse_data_config,
		load_corpora,

		# Word embeddings
		find_cluster_mean,
		get_cluster_matrix, 
		get_cluster_matrix!,
		find_close_clusters, 
		path 
		

	# Includes
	include("corpus.jl")
	include("parsers.jl")
	include("servers.jl")
	include("string.jl")
	include("search.jl")
	include("search_heuristics.jl")
	include("cmdline.jl")
	include("word_model_utils.jl")

end # module
