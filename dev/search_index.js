var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": "CurrentModule=Garamond"
},

{
    "location": "#Introduction-1",
    "page": "Introduction",
    "title": "Introduction",
    "category": "section",
    "text": "Garamond is a search engine that supports both classical and semantic search. The documentation is work in progress and has little coverage right now."
},

{
    "location": "#Installation-1",
    "page": "Introduction",
    "title": "Installation",
    "category": "section",
    "text": "Installation can be performed in several ways."
},

{
    "location": "#Git-cloning-1",
    "page": "Introduction",
    "title": "Git cloning",
    "category": "section",
    "text": "The Garamond repository can be downloaded through git:$ git clone https://github.com/zgornel/Garamond.jl"
},

{
    "location": "#Julia-REPL-1",
    "page": "Introduction",
    "title": "Julia REPL",
    "category": "section",
    "text": "The repository can also be downloaded from inside Julia. Entering the Pkg mode with ] and writing:add https://github.com/zgornel/Garamond.jl#masterwill download the master branch of the repository and add it to the current active development environment."
},

{
    "location": "#Simple-usage-example-1",
    "page": "Introduction",
    "title": "Simple usage example",
    "category": "section",
    "text": "#TODO"
},

{
    "location": "features/#",
    "page": "Feature list",
    "title": "Feature list",
    "category": "page",
    "text": ""
},

{
    "location": "features/#Feature-list-1",
    "page": "Feature list",
    "title": "Feature list",
    "category": "section",
    "text": "This is a list of the features supported by Garamond.Document Indexing/Modelling:\n[x] Single delimited file (rows are documents)\n[x] A directory (all files in all sub-directories that fit a globbing pattern are indexed)\n[x] Summarization support (index TextRank-based summary)\n[ ] Parallelism: green light or hardware threads\n[x] Basic update or \'re-indexing\' support\n[x] Single file support (parts of the file are treated as documents)\n[x] Multiple files / directory support (a file is a document)\n[x] File format support:\n[x] Text formats\n[x] .csv, .tsv etc.\n[x] .json (custom parser must be built)\n[x] .html (custom parser must be built)\n[ ] .xml\n[ ] Binary formats\n[ ] .pdf\n[ ] Compressed files (.zip, .gz, etc.)\n[ ] Microsoft new .xml formats(.docx, .xlsx, etc.)\n? Microsoft old binary formats(.doc, .xls, etc.)\nEngine configuration:\n[x] Single file for multiple data configurations\n[x] Multiple files for data configurations\n[ ] General engine configuration\nSearch types:\nClassic Search:\nLanguage support:\n[x] Uniform language: query language same as doc language\n[ ] Different languages for query / docs\nWhere to search:\n[x] Document data\n[x] Document metadata\n[x] Document data + metadata\nHow to search for patterns:\n[x] exact match\n[x] regular expression\nDocument term importance\n[x] term frequency\n[x] tf-idf\n[x] BM25\nSuggestion support\n[x] BK Trees (through BKTrees.jl)\n? Levenshtein Automata\n? SymSpell and others\nSemantic Search:\nLanguage support:\n[x] Uniform language: query language same as doc language (English, German, Romanian)(\n[x] Different languages for query / docs (ALMOST English, German, Romanian; to test :))\nWhere to search:\n[x] Document data\n[x] Document metadata\n[x] Document data + metadata\nDocument embedding:\n[x] Bag of words\n[x] Arora et al.\nEmbedding Vector libraries\n[x] Word2Vec embeddings\n[x] ConceptnetNumberbatch embeddings\n? GloVe embeddings\n? Other i.e. FastText\nSearch Models (for semantic vectors)\n[x] Naive cosine similarity base\n[x] Brute-force \"tree\" (multiple metrics)\n[x] KD-tree (multiple metrics)\n[x] HNSW (multiple metrics supported)\nI/O Iterface\n[x] Input: receive query data through UNIX sockets (when in server mode)\n[x] Output: output to socket (when in server mode), to STDOUT when in client mode\nPer-corpus embedding training\n[x] Word2Vec (manual)\n? Conceptnet\n? GloVe\nParallelism forms supported\n[x] Multi-threading (each corpus is searched withing a hardware thread; support is EXPERIMENTAL and it is disabled by default)\n[ ] Multi-core + task scheduling Dispatcher.jl for distributed corpora\n[ ] Cluster support\nOther:\n[x] Logging mechanism\n[x] Client/server functionality\n[x] Pretty version support :)"
},

{
    "location": "features/#Status-of-features-1",
    "page": "Feature list",
    "title": "Status of features",
    "category": "section",
    "text": "[x] supported\n[ ] to be added\n? not decided whether to add or not"
},

{
    "location": "clientserver/#",
    "page": "Client/Server",
    "title": "Client/Server",
    "category": "page",
    "text": ""
},

{
    "location": "clientserver/#Running-Garamond-in-server/client-mode-1",
    "page": "Client/Server",
    "title": "Running Garamond in server/client mode",
    "category": "section",
    "text": "Garamond is desinged as a client-server architecture in which the server receives queries, performs the search action and returns the results to a client that handles the interaction. The client can be either human or machine controlled."
},

{
    "location": "clientserver/#Command-line-utility-1",
    "page": "Client/Server",
    "title": "Command line utility",
    "category": "section",
    "text": "The main command line utility for Gramond is the script garamond.jl found in the root directory of the package. It is designed to be able to start the search server (i.e. server mode) and to send queries and receive results from the search server (i.e. client mode). The client mode serves testing purposes only and should not be used in production, it will be probably discontinued in the near future. A separate client (that just reads and writes to/from the socket) should be developed and readily available. To view the command line options for garamond.jl, run ./garamond.jl --help: % ./garamond.jl --help\nusage: garamond.jl [-d DATA-CONFIG] [-e ENGINE-CONFIG]\n                   [--log-level LOG-LEVEL] [-l LOG] [-s SOCKET]\n                   [-q QUERY] [--client] [--server] [-h]\n\noptional arguments:\n  -d, --data-config DATA-CONFIG\n                        data configuration file\n  -e, --engine-config ENGINE-CONFIG\n                        search engine configuration file (default: \"\")\n  --log-level LOG-LEVEL\n                        logging level (default: \"info\")\n  -l, --log LOG         logging stream (default: \"stdout\")\n  -s, --socket SOCKET   UNIX socket for data communication (default:\n                        \"/tmp/garamond/sockets/socket1\")\n  -q, --query QUERY     query the search engine if in client mode\n                        (default: \"\")\n  --client              client mode\n  --server              server mode\n  -h, --help            show this help message and exit"
},

{
    "location": "clientserver/#Server-mode-1",
    "page": "Client/Server",
    "title": "Server mode",
    "category": "section",
    "text": "In server mode, Garamond listens to a socket (i.e./tmp/garamond/sockets/socket1) for incoming queries. Once the query is received, it is processed and the answer written back to same socket. The following example starts Garamond in server mode (indexes the data and connects to socket, displaying all messages):$ ./garamond.jl --server -d ../extras_for_Garamond/data/Cornel/delimited/config_cornel_data_classic.json -s /tmp/garamond/sockets/socket1 --log-level debug\n[ [2018-11-18 15:29:17][DEBUG][garamond.jl:35] ~ GARAMOND ~ v\"0.0.0\" commit: 90f1a17 (2018-11-20)\n[ [2018-11-18 15:29:25][DEBUG][fsm.jl:41] Waiting for query...##Client modeIn client mode, the script sends the query to the server\'s socket and waits the search results on the same socket. Since it uses the whole package, client startup times are slow. View the notes for faster query alternatives. The following example performs a query using the server defined above (the socket is not specified as the server uses the default value):% ./garamond.jl --client --q \"arthur c clarke\" --log-level debug\n[ [2018-11-18 15:37:33][DEBUG][garamond.jl:35] ~ GARAMOND ~ v\"0.0.0\" commit: 90f1a17 (2018-11-20)\n[ [2018-11-18 15:37:33][DEBUG][io.jl:42] >>> Query sent.\n[ [2018-11-18 15:37:36][DEBUG][io.jl:44] <<< Search results received.\n[{\"id\":{\"id\":\"biglib-classic\"},\"query_matches\":{\"d\":{\"0.5441896\":[3],\"0.78605163\":[1,2],\"0.64313316\":[6,7],\"0.5895387\":[4,5]}},\"needle_matches\":{\"clarke\":1.5272124,\"arthur\":1.5272124,\"c\":1.5272124},\"suggestions\":{\"d\":{}}},{\"id\":{\"id\":\"techlib-classic\"},\"query_matches\":{\"d\":{\"0.053899456\":[1,5]}},\"needle_matches\":{\"c\":0.10779891},\"suggestions\":{\"d\":{}}}]"
},

{
    "location": "api/#Garamond.search-Union{Tuple{E}, Tuple{NaiveEmbeddingModel{E},Array{E,1},Int64}} where E<:AbstractFloat",
    "page": "API Reference",
    "title": "Garamond.search",
    "category": "method",
    "text": "search(model, point, k)\n\nSearches for the k nearest neighbors of point in data contained in the model. The model may vary from a simple wrapper inside a matrix to more complex structures such as k-d trees, etc.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.search-Union{Tuple{S}, Tuple{TermCounts,Array{S,1}}} where S<:AbstractString",
    "page": "API Reference",
    "title": "Garamond.search",
    "category": "method",
    "text": "search(termcnt, needles, method)\n\nSearch function for searching using the term imporatances associated to a corpus.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.search-Union{Tuple{V}, Tuple{V,Any}} where V<:(Array{#s232,1} where #s232<:(Searcher{D,E,M} where D<:StringAnalysis.AbstractDocument where E where M<:Garamond.AbstractSearchData))",
    "page": "API Reference",
    "title": "Garamond.search",
    "category": "method",
    "text": "search(srcher, query [;kwargs])\n\nSearches for query (i.e. key terms) in multiple corpora and returns information regarding the documents that match best the query. The function returns the search results in the form of a Vector{SearchResult}.\n\nArguments\n\nsrcher::AbstractVector{AbstractSearcher} is the corpora searcher\nquery the query\n\nKeyword arguments\n\nsearch_type::Symbol is the type of the search; can be :metadata,  :data or :all; the options specify that the query can be found in  the metadata of the documents of the corpus, the document content or both  respectively\nsearch_method::Symbol controls the type of matching: :exact  searches for the very same string while :regex searches for a string  in the corpus that includes the needle\nmax_matches::Int is the maximum number of search results to return from  each corpus\nmax_corpus_suggestions::Int is the maximum number of suggestions to return for  each missing needle from the search in a corpus\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.BruteTreeEmbeddingModel",
    "page": "API Reference",
    "title": "Garamond.BruteTreeEmbeddingModel",
    "category": "type",
    "text": "BruteTree model type for storing text embeddings. It is a wrapper around a BruteTree NN structure and performs brute search using a distance-based similarity between vectors.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.HNSWEmbeddingModel",
    "page": "API Reference",
    "title": "Garamond.HNSWEmbeddingModel",
    "category": "type",
    "text": "HNSW model type for storing text embeddings. It is a wrapper around a HierarchicalNSW (Hierarchical Navigable Small Worlds [1]) NN graph structure and performs a very efficient search using a distance-based similarity between vectors. [1] Yu. A. Malkov, D.A. Yashunin \"Efficient and robust approximate nearest     neighbor search using Hierarchical Navigable Small World graphs\"     (https://arxiv.org/abs/1603.09320)\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.KDTreeEmbeddingModel",
    "page": "API Reference",
    "title": "Garamond.KDTreeEmbeddingModel",
    "category": "type",
    "text": "K-D Tree model type for storing text embeddings. It is a wrapper around a KDTree NN structure and performs a more efficient search using a distance-based similarity between vectors.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.NaiveEmbeddingModel",
    "page": "API Reference",
    "title": "Garamond.NaiveEmbeddingModel",
    "category": "type",
    "text": "Naive model type for storing text embeddings. It is a wrapper around a matrix of embeddings and performs brute search using the cosine similarity between vectors.\n\n\n\n\n\n"
},

{
    "location": "api/#ConceptnetNumberbatch.embed_document-Union{Tuple{S2}, Tuple{H}, Tuple{T}, Tuple{S1}, Tuple{WordVectors{S1,T,H},Array{S2,1}}} where S2<:AbstractString where H<:Integer where T<:Real where S1<:AbstractString",
    "page": "API Reference",
    "title": "ConceptnetNumberbatch.embed_document",
    "category": "method",
    "text": "Function that embeds a document i.e. returns an embedding matrix, columns are word embeddings, using the word2vec WordVectors object. The function has an identical signature as the one from the ConceptnetNumberbatch package.\n\n\n\n\n\n"
},

{
    "location": "api/#ConceptnetNumberbatch.embed_document-Union{Tuple{T}, Tuple{Union{ConceptNet{#s222,#s221,T} where #s221<:AbstractString where #s222<:Language, WordVectors{#s30,T,#s29} where #s29<:Integer where #s30<:AbstractString},Dict{String,Int64},Array{String,1}}} where T<:AbstractFloat",
    "page": "API Reference",
    "title": "ConceptnetNumberbatch.embed_document",
    "category": "method",
    "text": "embed_document(embeddings_library, lexicon, document[; embedding_method])\n\nFunction to get from multiple sentencea to a document embedding. The embedding_method option controls how multiple sentence embeddings are combined into a single document embedding. Avalilable options for embedding_method:     :bow - calculates document embedding as the mean of the sentence embeddings     :arora - subtracts paragraph/phrase vector from each sentence embedding\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.build_corpus-Union{Tuple{T}, Tuple{S}, Tuple{Array{Array{S,1},1},Type{T},Array{DocumentMetadata,1}}} where T<:StringAnalysis.AbstractDocument where S<:AbstractString",
    "page": "API Reference",
    "title": "Garamond.build_corpus",
    "category": "method",
    "text": "build_corpus(documents, doctype, metadata_vector)\n\nBuilds a corpus of documents of type doctype using the data in documents and metadata from metadata_vector.\n\nNote: No preprocessing is performed at this step, it is assumed that the data       has already been preprocessed and is ready to be searched in.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.build_logger",
    "page": "API Reference",
    "title": "Garamond.build_logger",
    "category": "function",
    "text": "build_logger(logging_stream, log_level)\n\nBuilds a logger using the stream and loglevel provided. These should be coming from parsing the input arguments. The loggingstream can take the values:  • \"null\": logs to /dev/null  • \"stdout\": logs to standard output  • \"/path/to/existing/file\": logs to an existing file  • \"/path/to/non-existing/file\": creates the log file If no valid option is provided, the default stream is the standard output. The log level can take the values: \"debug\", \"info\", \"error\" and defaults to \"info\" if no valid option is provided.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.build_searcher-Tuple{SearchConfig}",
    "page": "API Reference",
    "title": "Garamond.build_searcher",
    "category": "method",
    "text": "build_searcher(sconf)\n\nCreates a Searcher from a SearchConfig.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.garamond_log_formatter-NTuple{6,Any}",
    "page": "API Reference",
    "title": "Garamond.garamond_log_formatter",
    "category": "method",
    "text": "garamond_log_formatter(level, _module, group, id, file, line)\n\nGaramond -specific log message formatter. Takes a fixed set of input arguments and returns the color, prefix and suffix for the log message.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.get_parsing_function-Tuple{Symbol,Bool,String,String,Bool,Int64,Bool}",
    "page": "API Reference",
    "title": "Garamond.get_parsing_function",
    "category": "method",
    "text": "get_parsing_function(args...)\n\nFunction that generates a parsing function from its input arguments and returns it.\n\nArguments\n\nparser::Symbol is the name of the parser\nheader::Bool whether the file has a header or not (for delimited files only)\ndelimiter::String the delimiting character (for delimited files only)\nglobbing_pattern::String globbing pattern for gathering file lists from directories (for directory parsers only)\nbuild_summary::Bool whether to use a summary instead of the full document (for directory parsers only)\nsummary_ns::Int how many sentences to use in the summary (for directory parsers only)\nshow_progress::Bool whether to show the progress when loading files\n\nNote: parser must be in the keys of the PARSER_CONFIGS constant. The name       of the data parsing function is created as: :__parser_<parser> so,       the function name :__parser_delimited_format_1 corresponds to the       parser :delimited_format_1. The function must be defined apriori.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.load_search_configs-Tuple{AbstractString}",
    "page": "API Reference",
    "title": "Garamond.load_search_configs",
    "category": "method",
    "text": "load_search_configs(filename)\n\nFunction that creates search configurations from a data configuration file specified by filename. It returns a Vector{SearchConfig} that is used to build the Searcher objects with which search is performed.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.prepare_query-Tuple{AbstractString,UInt32}",
    "page": "API Reference",
    "title": "Garamond.prepare_query",
    "category": "method",
    "text": "prepare_query(query, flags)\n\nPrepares the query for search (tokenization if the case), pre-processing.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.printable_version-Tuple{}",
    "page": "API Reference",
    "title": "Garamond.printable_version",
    "category": "method",
    "text": "printable_version()\n\nReturns a pretty version string that includes the git commit and date.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.recursive_glob",
    "page": "API Reference",
    "title": "Garamond.recursive_glob",
    "category": "function",
    "text": "recursive_glob(pattern, path)\n\nGlobs recursively all the files matching the pattern, at the given path.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.search_heuristically!-Union{Tuple{S}, Tuple{MultiDict{String,Tuple{Float32,String}},BKTree{String},Array{S,1}}} where S<:AbstractString",
    "page": "API Reference",
    "title": "Garamond.search_heuristically!",
    "category": "method",
    "text": "search_heuristically!(suggestions, search_tree, needles [;max_suggestions=1])\n\nSearches in the search tree for partial matches of the needles.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.squash-Union{Tuple{Array{T,2}}, Tuple{T}} where T<:AbstractFloat",
    "page": "API Reference",
    "title": "Garamond.squash",
    "category": "method",
    "text": "squash(m)\n\nFunction that creates a single mean vector from a matrix m and performs some normalization operations as well.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.squash-Union{Tuple{T}, Tuple{Array{Array{T,1},1},Int64}} where T<:AbstractFloat",
    "page": "API Reference",
    "title": "Garamond.squash",
    "category": "method",
    "text": "squash(vv, m)\n\nFunction that creates a single mean vector from a vector of vectors vv where each vector has a length m and performs some normalization operations as well.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.summarize-Union{Tuple{Array{S,1}}, Tuple{S}} where S<:AbstractString",
    "page": "API Reference",
    "title": "Garamond.summarize",
    "category": "method",
    "text": "summarize(sentences [;ns=1, flags=SUMMARIZATION_FLAGS]\n\nBuild a summary of the text\'s sentences. The resulting summary will be a ns sentence document; each sentence is pre-procesed using the flags option.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.version-Tuple{}",
    "page": "API Reference",
    "title": "Garamond.version",
    "category": "method",
    "text": "version()\n\nReturns the current Garamond version using the Project.toml and git. If the Project.toml, git are not available, the version defaults to an empty string.\n\n\n\n\n\n"
},

{
    "location": "api/#",
    "page": "API Reference",
    "title": "API Reference",
    "category": "page",
    "text": "Modules = [Garamond]"
},

]}
