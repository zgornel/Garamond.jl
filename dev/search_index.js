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
    "text": "Garamond is a search engine that supports both classical and semantic search. It is designed to be used both as a Julia package, with search functionality available through API method calls, as well as a standalone search server with search functionality accessible through clients that connect to and query the server."
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
    "text": ""
},

{
    "location": "#Classic-search-1",
    "page": "Introduction",
    "title": "Classic search",
    "category": "section",
    "text": "The following code snippet runs a quick and dirty search:# Use packages\nusing Pkg;\nPkg.activate(\".\");\nusing Garamond\n\n# Load searchers\nfilepath = [\"/home/zgornel/projects/extras_for_Garamond/data/Cornel/delimited/config_cornel_data_classic.json\"]\nsrchers = load_searchers(filepath);\n\n# Search\nQUERY = \"arthur clarke pattern\"\nresults = search(srchers, QUERY)The search results promptly appear:# 2-element Array{SearchResult,1}:\n#  Search results for id=\"biglib-classic\":  7 hits, 2 query terms, 0 suggestions.\n#  Search results for id=\"techlib-classic\":  2 hits, 1 query terms, 0 suggestions.To view them in a more detailed fashion i.e. including metadata, one can run:print_search_results(srchers, results)which prints:# 9 search results from 2 corpora\n# `-[id=\"biglib-classic\"] 7 search results:\n#   2.9344456 ~ 1-[\"The last theorem\" by Arthur C. Clarke, 2008 (2010)]\n#   2.5842855 ~ 2-[\"2010: odyssey two\" by Arthur C. Clarke, 1982 (2010)]\n#   2.059056 ~ 4-[\"Childhood\'s end\" by Arthur C. Clarke, 1954 (2013)]\n#   2.059056 ~ 6-[\"3001: the final odyssey\" by Arthur C. Clarke, 1968 (1997)]\n#   2.059056 ~ 7-[\"2061: odyssey three\" by Arthur C. Clarke, 1987 (1988)]\n#   1.8586512 ~ 3-[\"The city and the stars\" by Arthur C. Clarke, 1956 (2003)]\n#   1.8586512 ~ 5-[\"2001: a space odyssey\" by Arthur C. Clarke, 1968 (2001)]\n# `-[id=\"techlib-classic\"] 2 search results:\n#   0.6101619 ~ 3-[\"Pattern recognition 4\'th edition\" by Sergios Theodoridis, Konstantinos Koutroumbas, 2008 (2008)]\n#   0.37574464 ~ 2-[\"Pattern classification, 2\'nd edition\" by Richard O. Douda, Peter E. Hart, David G. Stork, 2000 (2000)]"
},

{
    "location": "#Semantic-search-1",
    "page": "Introduction",
    "title": "Semantic search",
    "category": "section",
    "text": "Performing a semantic search is very similar to performing a classic one, the difference being that another data configuration file must be provided:# Load searchers\nfilepath = [\"/home/zgornel/projects/extras_for_Garamond/data/Cornel/delimited/config_cornel_data_semantic.json\"]\nsrchers = load_searchers(filepath);\n\n# Search\nQUERY = \"space fiction and planets galore\"\nresults = search(srchers, QUERY, max_matches=10)which yields:# 2-element Array{SearchResult,1}:\n#  Search results for id=\"biglib-semantic\":  10 hits, 0 query terms, 0 suggestions.\n#  Search results for id=\"techlib-semantic\":  5 hits, 0 query terms, 0 suggestions.In this case,print_search_results(srchers, results)prints:# 15 search results from 2 corpora\n# `-[id=\"biglib-semantic\"] 10 search results:\n#   1.4016596138408786 ~ 5-[\"2001: a space odyssey\" by Arthur C. Clarke, 1968 (2001)]\n#   1.3030687835002375 ~ 3-[\"The city and the stars\" by Arthur C. Clarke, 1956 (2003)]\n#   1.1831628403122616 ~ 2-[\"2010: odyssey two\" by Arthur C. Clarke, 1982 (2010)]\n#   1.1558528687320448 ~ 65-[\"Of love and other demons\" by Gabriel Garcia Marquez, 1994 (2012)]\n#   1.1384422864227708 ~ 10-[\"A legend of the future\" by Augustin De Rojas, 1985 (2014)]\n#   1.0947549384771254 ~ 62-[\"Love in the time of cholera\" by Gabriel Garcia Marquez, 1985 (2012)]\n#   1.0729641968647925 ~ 31-[\"The devil and the good lord\" by Jean-Paul Sartre, 1951 (2007)]\n#   1.0320209929919373 ~ 1-[\"The last theorem\" by Arthur C. Clarke, 2008 (2010)]\n#   1.0250176565568312 ~ 21-[\"In the miso soup\" by Ryu Murakami, 1997 (2006)]\n#   1.0 ~ 47-[\"Jailbird\" by Kurt Vonnegut, 1979 (2009)]\n# `-[id=\"techlib-semantic\"] 5 search results:\n#   1.1470548192935575 ~ 1-[\"Data classification: algorithms and applications\" by Charu C. Aggarwal, 2014 (2014)]\n#   0.9473624595100231 ~ 5-[\"Numerical methods for engineers\" by Steven C. Chapra, Raymond P. Canale, 2014 (2014)]\n#   0.8689249981976931 ~ 3-[\"Pattern recognition 4\'th edition\" by Sergios Theodoridis, Konstantinos Koutroumbas, 2008 (2008)]\n#   0.8644211963883863 ~ 4-[\"Artificial intelligence, a modern approach 3\'rd edition\" by Stuart Russel, Peter Norvig, 2009 (2016)]\n#   0.7924568154973227 ~ 2-[\"Pattern classification, 2\'nd edition\" by Richard O. Douda, Peter E. Hart, David G. Stork, 2000 (2000)]"
},

{
    "location": "configuration/#",
    "page": "Configuration",
    "title": "Configuration",
    "category": "page",
    "text": ""
},

{
    "location": "configuration/#Configuration-1",
    "page": "Configuration",
    "title": "Configuration",
    "category": "section",
    "text": "The configuration options of the Garamond search engine can be logically split into three main categories, based on what they tend to operate on and where they actually reside:data - the data configuration pertains to the way the data is indexed and the implicitly, the type of search operation i.e. classic or semantic it supports. In this category one can count options such as the type of search being performed, the path to the actual files to be indexed, the specific parser to use, the path and type of embeddings libraries to be used for semantic search and so on. The data configuration format is a simple JSON file in which multiple configurations for the same or distinct datasets can reside. The engine supports loading multiple such configuration files, providing additional flexibility to the user in choosing how to construct the search structures that guide the search given the particularities of their data. One could for example perform several searches using in the same data or a single search on several distinct datasets.\nengine - the engine configuration file is a simple run-control file named .garamondrc that has to reside in the user home directory on UNIX-like systems i.e. ~/.garamondrc. The configuration file is parsed entirely as Julia code at the startup of the search server - if the file exists - and pre-compiled into the engine itself. The file defines options that pertain to external programs such as the pdf to text converter and replacement values for several default internal variables of the engine such as what type of StringAnalysis document objects the documents are internally represented as, how many search results to return by default, the maximum edit distance to be used when searching for suggestions for possibly misspelled query terms and so on.\ninternal - the engine default configuration variable values for as well as necessary constants such as text preprocessing flags (a flag describes a full set of operations to be performed on input text) reside in the src/config/defaults.jl file and can be modified prior to running the search server. Please note that such operation will also result in new compilation of the package."
},

{
    "location": "configuration/#Data-configuration-1",
    "page": "Configuration",
    "title": "Data configuration",
    "category": "section",
    "text": "This section will be added at a latter time."
},

{
    "location": "configuration/#Engine-configuration-1",
    "page": "Configuration",
    "title": "Engine configuration",
    "category": "section",
    "text": "A sample ~/.garamondrc file with all available configuration options filled would look like:# Text to pdf program\nconst PDFTOTEXT_PROGRAM = \"/bin/pdftotext\"\n\n# Type of StrinAnalysis document\nconst DOCUMENT_TYPE = StringAnalysis.NGramDocument{String}\n\n# Maximum edit distance for suggestion search\nconst MAX_EDIT_DISTANCE = 2\n\n# Default maximum matches to return\nconst MAX_MATCHES = 1_000\n\n# Default maximum number of suggestions to return\n# for each non-matched query term when squashing\n# results from several corpora\nconst MAX_SUGGESTIONS = 10\n\n# Default maximum number of suggestions to return\n# for each non-matched query term when searching\n# in a single corpus\nconst MAX_CORPUS_SUGGESTIONS = 5"
},

{
    "location": "configuration/#Internal-configuration-1",
    "page": "Configuration",
    "title": "Internal configuration",
    "category": "section",
    "text": "The full internal configuration of the engine can be readily viewed in src/config/defaults.jl."
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
    "text": "Garamond is designed as a client-server architecture in which the server receives queries, performs the search action and returns the results to a client that handles the interaction. The client can be either human or machine controlled. There are three utilities designed to handle the search process, all of which can be found in the root directory of the package:gars - starts the search server. The operations performed by the search engine server at this point are indexing data at a given location and listening to a socket.\ngarc - command line client supporting Unix socket communication. It is the most feature complete of the two clients. Through it, a single search can be performed and all search parameters can be specified. It supports pretty printing as well as a means of visually investigating the results of the search.\ngarw - web client supporting Web socket communication (EXPERIMENTAL). The basic principle is that the client starts a HTTP server which serves a page at a given HTTP port. If the web page is not specified, a default one is generated internally and served. The user connects with a web browser of choice at the local address (i.e. 127.0.0.1) and specified port and performs the search queries from the page. It naturally supports multiple queries however, the parameters of the search cannot be changed.Notes:The clients do not depend on the Garamond package and are very lightweight.\nIn the future, garw should support a query format through which the types of searches and their parameters can be controlled. Such options can include performing exact or regex matches, the number of maximum results to return etc.\nThe clients are currently the only \'easy\' way to communicate with the search server; communication with the latter is pretty straightforward (i.e. reading and writing from sockets) as long as the JSON format for data communication is respected."
},

{
    "location": "clientserver/#Starting-the-search-server-1",
    "page": "Client/Server",
    "title": "Starting the search server",
    "category": "section",
    "text": "The search server listens to a socket for incoming queries. Once the query is received, it is processed and the answer written back to same socket. Looking at the gars utility help$ ./gars --help\nusage: gars -d DATA-CONFIG [--log-level LOG-LEVEL] [-l LOG]\n            [-u UNIX-SOCKET] [-w WEB-SOCKET-PORT] [-h]\n\noptional arguments:\n  -d, --data-config DATA-CONFIG\n                        data configuration file\n  --log-level LOG-LEVEL\n                        logging level (default: \"info\")\n  -l, --log LOG         logging stream (default: \"stdout\")\n  -u, --unix-socket UNIX-SOCKET\n                        UNIX socket for data communication\n  -w, --web-socket-port WEB-SOCKET-PORT\n                        WEB socket data communication port (type:\n                        UInt16)\n  -h, --help            show this help message and exitstarting the server becomes quite straightforward. To start the server listening to a web socket at port 8081, all one has to do is:$ ./gars -d ../extras_for_Garamond/data/Cornel/delimited/config_cornel_data_semantic.json -w 8081 --log-level info\n[ [2018-12-18 12:26:59][INFO][servers.jl:102] ~ GARAMOND ~ v\"0.0.0\" commit: 4d7be0d (2018-12-07)\n[ [2018-12-18 12:27:21][INFO][servers.jl:25] I/O: Waiting for data @web-socket:8081...\n[ [2018-12-18 12:27:22][INFO][Servers.jl:301] Listening on: Sockets.InetAddr{Sockets.IPv4}(ip\"127.0.0.1\", 0x1f91)Notice that the -d switch allows indicating a data configuration to use. Multiple such configurations can be provided if multiple data sources are to be handled. After running the command, information-level output of the server is being written to the standard output stream. To write directly the server logs to a file, a file can be indicated through the -log switch or the output redirected to a file."
},

{
    "location": "clientserver/#Commandline-client-1",
    "page": "Client/Server",
    "title": "Commandline client",
    "category": "section",
    "text": "The commandline client garc sends the query to an open Unix socket and waits the search results on the same socket. It is worthwhile checking the available commandline options:$ ./garc --help\nusage: garc [--log-level LOG-LEVEL] -u UNIX-SOCKET [--pretty]\n            [--max-matches MAX-MATCHES] [--search-type SEARCH-TYPE]\n            [--search-method SEARCH-METHOD]\n            [--max-suggestions MAX-SUGGESTIONS] [-k] [-h] query\n\npositional arguments:\n  query                 the search query (default: \"\")\n\noptional arguments:\n  --log-level LOG-LEVEL\n                        logging level (default: \"warn\")\n  -u, --unix-socket UNIX-SOCKET\n                        UNIX socket for data communication\n  --pretty              output is a pretty print of the results\n  --max-matches MAX-MATCHES\n                        maximum results to return (type: Int64,\n                        default: 10)\n  --search-type SEARCH-TYPE\n                        type of search (type: Symbol, default:\n                        :metadata)\n  --search-method SEARCH-METHOD\n                        type of search (type: Symbol, default: :exact)\n  --max-suggestions MAX-SUGGESTIONS\n                        How many suggestions to return for each\n                        mismatched query term (type: Int64, default:\n                        0)\n  -k, --kill            Kill the search engine server\n  -h, --help            show this help message and exitAssuming that a search server was started with$ ./gars -d ../extras_for_Garamond/data/Cornel/delimited/config_cornel_data_semantic.json -u /tmp/_garamond_socket_001 --log-level infothe following example performs a query using the server defined above and displays the results in a human readable way:$ ./garc \"paolo coelho\" -u /tmp/_garamond_socket_001 --max-matches 5 --pretty --log-level debug\n┌ Debug: ~ GARAMOND~ (unix-socket client)\n└ @ Main.GaramondCLIClient ~/projects/Garamond.jl/garc:134\n┌ Debug: >>> Request sent.\n└ @ Main.GaramondCLIClient ~/projects/Garamond.jl/garc:62\n┌ Debug: <<< Search results received.\n└ @ Main.GaramondCLIClient ~/projects/Garamond.jl/garc:64\n10 search results from 2 corpora\n`-[id=\"biglib-semantic\"] 5 search results:\n  0.9740912108947957 ~ 50-[\"The tunnel\" by Ernesto Sabato, 1948 (2004)]\n  0.9598814147037482 ~ 63-[\"The autumn of the patriarch\" by Gabriel Garcia Marquez, 1975 (2005)]\n  0.9417322045431806 ~ 48-[\"Dialogues\" by Louis Borges, Ernesto Sabato, 1976 (2005)]\n  0.9380608114354404 ~ 49-[\"Essays\" by Ernesto Sabato, 1996 (2005)]\n  0.9262495410707653 ~ 61-[\"The green house\" by Mario Vargas Llosa, 1965 (2008)]\n`-[id=\"techlib-semantic\"] 5 search results:\n  0.8118677136424433 ~ 3-[\"Pattern recognition 4\'th edition\" by Sergios Theodoridis, Konstantinos Koutroumbas, 2008 (2008)]\n  0.804295301024025 ~ 2-[\"Pattern classification, 2\'nd edition\" by Richard O. Douda, Peter E. Hart, David G. Stork, 2000 (2000)]\n  0.7892832305144111 ~ 4-[\"Artificial intelligence, a modern approach 3\'rd edition\" by Stuart Russel, Peter Norvig, 2009 (2016)]\n  0.7713395077452254 ~ 5-[\"Numerical methods for engineers\" by Steven C. Chapra, Raymond P. Canale, 2014 (2014)]\n  0.7603241404778367 ~ 1-[\"Data classification: algorithms and applications\" by Charu C. Aggarwal, 2014 (2014)]\n-----\nElapsed search time: 0.0005221366882324219 seconds.Please not that the search returned five results from each corpus, ordered by relevance. Also, there is are no books by Paolo Coelho in the library (fortunately). The time indicated is from a second run of the query, the first query runs always takes longer (~1s) as the code needs to be compiled on-the-fly."
},

{
    "location": "clientserver/#Web-client-1",
    "page": "Client/Server",
    "title": "Web client",
    "category": "section",
    "text": "The web client garw starts a HTTP server that locally serves a page: it is the page that has to actually connect to the search server through a user-specified web-socket. Therefore, garw is technically not fully a client but for the sake of consistency we will consider it to be one. Its commandline arguments are more simplistic:$ ./garw --help\nusage: garw [--log-level LOG-LEVEL] -w WEB-SOCKET-PORT [-p HTTP-PORT]\n             [--web-page WEB-PAGE] [-h]\n\noptional arguments:\n  --log-level LOG-LEVEL\n                        logging level (default: \"warn\")\n  -w, --web-socket-port WEB-SOCKET-PORT\n                        WEB socket data communication port (type:\n                        UInt16)\n  -p, --http-port HTTP-PORT\n                        HTTP port for the http server (type: Int64,\n                        default: 9999)\n  --web-page WEB-PAGE   Search web page to serve\n  -h, --help            show this help message and exitAssuming a search server is running using a web socket at port 8081 (as in the first gars example above), one can start serving the default webpage at the default port by simply running:$ ./garw -w 8081\n[ Info: Listening on: Sockets.InetAddr{Sockets.IPv4}(ip\"127.0.0.1\", 0x270f)Once a browser opens the page at locahost:9999, output will be generated by garw (by the HTTP.jl module more exactly) regarding the connections occurring:[ Info: Accept (0):  🔗    0↑     0↓    1s 127.0.0.1:9999:9999 ≣16\n┌ Warning: throttling 127.0.0.1\n└ @ HTTP.Servers ~/.julia/packages/HTTP/YjRCz/src/Servers.jl:121\n┌ Info: HTTP.Messages.Request:\n│ \"\"\"\n│ GET /? HTTP/1.1\n│ Host: localhost:9999\n│ Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\n│ User-Agent: mozilla\n│ Upgrade-Insecure-Requests: 1\n│ Accept-Encoding: gzip, deflate\n│ Accept-Language: en-US\n│ Connection: Keep-Alive\n│\n└ \"\"\"From this point on, one can have fun searching using the webpage."
},

{
    "location": "notes/#",
    "page": "Notes",
    "title": "Notes",
    "category": "page",
    "text": ""
},

{
    "location": "notes/#Notes-1",
    "page": "Notes",
    "title": "Notes",
    "category": "section",
    "text": ""
},

{
    "location": "notes/#Multi-threading-1",
    "page": "Notes",
    "title": "Multi-threading",
    "category": "section",
    "text": "Using multi-threading in Garamond is not recommended (as of Julia versions v\"1.0.2\" / v\"1.1-dev\") as floating point operations are not thread-safe. If one chooses to use multi-threading i.e. through the @threads macro for example, the following exports: OPENBLAS_NUM_THREADS=1 and JULIA_NUM_THREADS=<n> have to be performed for multi-threading to work efficiently."
},

{
    "location": "notes/#Unix-socket-tips-and-tricks-1",
    "page": "Notes",
    "title": "Unix socket tips and tricks",
    "category": "section",
    "text": "The examples below assume the existence of a Unix socket at the location /tmp/<unix_socket> (the socket name is not specified).To redirect a TCP socket to a UNIX socket: socat TCP-LISTEN:<tcp_port>,reuseaddr,fork UNIX-CLIENT:/tmp/<unix_socket> or socat TCP-LISTEN:<tcp_port>,bind=127.0.0.1,reuseaddr,fork,su=nobody,range=127.0.0.0/8 UNIX-CLIENT:/tmp/<unix_socket>\nTo send a query to a Garamond server (no reply, for debugging purposes): echo \'find me a needle\' | socat - UNIX-CONNECT:/tmp/garamond/sockets/<unix_socket>\nFor interactive send/receive, socat UNIX-CONNECT:/tmp/garamond/sockets/<unix_socket> STDOUT"
},

{
    "location": "features/#",
    "page": "Feature list",
    "title": "Feature list",
    "category": "page",
    "text": ""
},

{
    "location": "features/#Features-1",
    "page": "Feature list",
    "title": "Features",
    "category": "section",
    "text": "This is a list of the features supported by Garamond.Document Indexing/Modelling:\n[x] Summarization support (index TextRank-based summary)\n[ ] Parallelism: green light or hardware threads\n[x] Basic update or \'re-indexing\' support\n[x] Single file support (parts of the file are treated as documents)\n[x] Multiple files / directory support (a file is a document)\n[x] File format support:\n[x] Text formats\n[x] .csv, .tsv etc.\n[x] .json (custom parser must be built)\n[x] .html (custom parser must be built)\n[x] .xml (custom parser must be built)\n[x] Binary formats\n[x] .pdf (through external program pdftotext from libpoppler)\n[ ] Compressed files (.tar, .zip, .gz, etc.)\n[ ] Microsoft new .xml formats(.docx, .xlsx, etc.)\nEngine configuration:\n[x] Single file for multiple data configurations\n[x] Multiple files for data configurations\n[x] General engine configuration (~/.garamondrc.jl, gets re-compiled into Garamond at startup)\nSearch types:\nClassic Search:\nLanguage support:\n[x] Uniform language: query language same as doc language\n[ ] Different languages for query / docs\nWhere to search:\n[x] Document data\n[x] Document metadata\n[x] Document data + metadata\nHow to search for patterns:\n[x] exact match\n[x] regular expression\nDocument term importance\n[x] term frequency\n[x] tf-idf\n[x] BM25\nSuggestion support\n[x] BK Trees (through BKTrees.jl)\n[ ] Levenshtein automata\n[ ] SymSpell-like approaches\nSemantic Search:\nLanguage support:\n[x] Uniform language: query language same as doc language (English, German, Romanian)(\n[x] Different languages for query / docs (ALMOST English, German, Romanian; to test :))\nWhere to search:\n[x] Document data\n[x] Document metadata\n[x] Document data + metadata\nDocument embedding:\n[x] Bag of words\n[x] SIF (Smooth inverse frequency)\nEmbedding Vector libraries\n[x] Word2Vec\n[x] ConceptnetNumberbatch\n[x] GloVe\nSearch Models (for semantic vectors)\n[x] Naive i.e. cosine similarity\n[x] Brute-force \"tree\", uses Euclidean metrics\n[x] KD-tree, uses Euclidean metrics\n[x] HNSW, uses Euclidean metrics\nI/O Iterface\n[x] Server: communication through UNIX/Web sockets\n[x] CLI Client: input and output are STDIN and STDOUT (communication through Unix sockets)\n[x] HTTP Client: input and output are in a webpage (communication through Web sockets)\nEmbedding training support\n[x] Word2Vec (offline training)\n[x] GloVe (offline training)\n[ ] Conceptnet\nParallelism forms supported\n[x] Multi-threading (each corpus is searched withing a hardware thread; support is EXPERIMENTAL and it is disabled by default)\n[ ] Multi-core + task scheduling Dispatcher.jl for distributed corpora\n[ ] Cluster support\nOther:\n[x] Logging mechanism\n[x] Client/server functionality\n[x] Pretty version support :)The status of the features is as follows:[x] supported\n[ ] not available (yet)"
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
    "location": "api/#Garamond.search-Union{Tuple{V}, Tuple{V,Any}} where V<:(Array{#s304,1} where #s304<:(Searcher{D,E,M} where D<:StringAnalysis.AbstractDocument where E where M<:Garamond.AbstractSearchData))",
    "page": "API Reference",
    "title": "Garamond.search",
    "category": "method",
    "text": "search(srcher, query [;kwargs])\n\nSearches for query (i.e. key terms) in multiple corpora and returns information regarding the documents that match best the query. The function returns the search results in the form of a Vector{SearchResult}.\n\nArguments\n\nsrcher::AbstractVector{AbstractSearcher} is the corpora searcher\nquery the query\n\nKeyword arguments\n\nsearch_type::Symbol is the type of the search; can be :metadata,  :data or :all; the options specify that the query can be found in  the metadata of the documents of the corpus, the document content or both  respectively\nsearch_method::Symbol controls the type of matching: :exact  searches for the very same string while :regex searches for a string  in the corpus that includes the needle\nmax_matches::Int is the maximum number of search results to return from  each corpus\nmax_corpus_suggestions::Int is the maximum number of suggestions to return for  each missing needle from the search in a corpus\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.ERRORED_REQUEST",
    "page": "API Reference",
    "title": "Garamond.ERRORED_REQUEST",
    "category": "constant",
    "text": "Standard deconstructed request corresponding to an error request.\n\n\n\n\n\n"
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
    "location": "api/#ConceptnetNumberbatch.embed_document-Union{Tuple{S2}, Tuple{H}, Tuple{T}, Tuple{S1}, Tuple{Union{WordVectors{S1,T,H}, WordVectors{S1,T,H}},Array{S2,1}}} where S2<:AbstractString where H<:Integer where T<:Real where S1<:AbstractString",
    "page": "API Reference",
    "title": "ConceptnetNumberbatch.embed_document",
    "category": "method",
    "text": "Function that embeds a document i.e. returns an embedding matrix, columns are word embeddings, using the Word2Vec or Glowe WordVectors object. The function has an identical signature as the one from the ConceptnetNumberbatch package.\n\n\n\n\n\n"
},

{
    "location": "api/#ConceptnetNumberbatch.embed_document-Union{Tuple{T}, Tuple{Union{ConceptNet{#s288,#s59,T} where #s59<:AbstractString where #s288<:Language, WordVectors{#s56,T,#s55} where #s55<:Integer where #s56<:AbstractString, WordVectors{#s58,T,#s57} where #s57<:Integer where #s58<:AbstractString},Dict{String,Int64},Array{String,1}}} where T<:AbstractFloat",
    "page": "API Reference",
    "title": "ConceptnetNumberbatch.embed_document",
    "category": "method",
    "text": "embed_document(embeddings_library, lexicon, document[; embedding_method])\n\nFunction to get from multiple sentencea to a document embedding. The embedding_method option controls how multiple sentence embeddings are combined into a single document embedding. Avalilable options for embedding_method:     :bow - calculates document embedding as the mean of the sentence embeddings     :sif - smooth-inverse-frequency subtracts paragraph/phrase vector            from each sentence embedding\n\n\n\n\n\n"
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
    "location": "api/#Garamond.construct_response-Tuple{Any,Any,String}",
    "page": "API Reference",
    "title": "Garamond.construct_response",
    "category": "method",
    "text": "construct_response(srchers, results, what [; kwargs...])\n\nFunction that constructs a response for a Garamond client using the search results, data from srchers and specifier what.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.deconstruct_request-Tuple{String}",
    "page": "API Reference",
    "title": "Garamond.deconstruct_request",
    "category": "method",
    "text": "deconstruct_request(request)\n\nFunction that deconstructs a Garamond request received from a client into individual search engine operations and search parameters.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.detect_language-Tuple{AbstractString}",
    "page": "API Reference",
    "title": "Garamond.detect_language",
    "category": "method",
    "text": "detect_language(text [; default=DEFAULT_LANGUAGE])\n\nDetects the language of a piece of text. Returns a language of type Languages.Language. If the text is empty of the confidence is low, return the default language.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.garamond_log_formatter-NTuple{6,Any}",
    "page": "API Reference",
    "title": "Garamond.garamond_log_formatter",
    "category": "method",
    "text": "garamond_log_formatter(level, _module, group, id, file, line)\n\nGaramond -specific log message formatter. Takes a fixed set of input arguments and returns the color, prefix and suffix for the log message.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.get_parsing_function-Tuple{Symbol,Union{Nothing, Dict},Bool,String,String,String,Bool,Int64,UInt32,Bool}",
    "page": "API Reference",
    "title": "Garamond.get_parsing_function",
    "category": "method",
    "text": "get_parsing_function(args...)\n\nFunction that generates a parsing function from its input arguments and returns it.\n\nArguments\n\nparser::Symbol is the name of the parser\nparser_config::Union{Nothing, Dict} can contain optional configuration data for the parser (for delimited parsers)\nheader::Bool whether the file has a header or not (for delimited files only)\ndelimiter::String the delimiting character (for delimited files only)\nglobbing_pattern::String globbing pattern for gathering file lists from directories (for directory parsers only)\nlanguage::String the plain English name of the language; use \"auto\" for\n\ndocument-level language autodetection\n\nbuild_summary::Bool whether to use a summary instead of the full document (for directory parsers only)\nsummary_ns::Int how many sentences to use in the summary (for directory parsers only)\nsummarization_strip_flags::UInt32 flags used to strip text before summarization (for directory parsers only)\nshow_progress::Bool whether to show the progress when loading files\n\nNote: parser must be in the keys of the PARSER_CONFIGS constant. The name       of the data parsing function is created as: :__parser_<parser> so,       the function name :__parser_delimited_format_1 corresponds to the       parser :delimited_format_1. The function must be defined apriori.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.ioserver-Tuple{AbstractString,Channel{String}}",
    "page": "API Reference",
    "title": "Garamond.ioserver",
    "category": "method",
    "text": "ioserver(socket_or_port::Union{UInt16, AbstractString}, channel::Channel{String})\n\nWrapper for the UNIX- or WEB- socket servers.\n\n\n\n\n\n"
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
    "location": "api/#Garamond.search_server-Tuple{Any,Any,Any}",
    "page": "API Reference",
    "title": "Garamond.search_server",
    "category": "method",
    "text": "search_server(data_config_paths, socket, ws_port)\n\nMain server function of Garamond. It is a finite-state-machine that when called, creates the searchers i.e. search objects using the data_config_paths and the proceeds to looping continuously in order to:     • update the searchers regularly;     • receive requests from clients using the unix-socket       socket or/and a web-socket at port ws_port;     • call search and route responses back to the clients       through their corresponding sockets\n\nBoth searcher update and I/O communication are performed asynchronously.\n\n\n\n\n\n"
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
    "text": "summarize(sentences [;ns=1, flags=DEFAULT_SUMMARIZATION_STRIP_FLAGS])\n\nBuild a summary of the text\'s sentences. The resulting summary will be a ns sentence document; each sentence is pre-procesed using the flags option.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.unix_socket_server-Tuple{AbstractString,Channel{String}}",
    "page": "API Reference",
    "title": "Garamond.unix_socket_server",
    "category": "method",
    "text": "unix_socket_server(socket::AbstractString, channel::Channel{String})\n\nStarts a bi-directional unix socket server that uses a UNIX-socket socket and communicates with the search server through a channel channel.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.updater-Union{Tuple{Array{S,1}}, Tuple{S}} where S<:AbstractSearcher",
    "page": "API Reference",
    "title": "Garamond.updater",
    "category": "method",
    "text": "updater(searchers, channel, update_interval)\n\nFunction that regularly updates the searchers at each update_interval seconds, and puts the updates on the channel to be sent to the search server.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.version-Tuple{}",
    "page": "API Reference",
    "title": "Garamond.version",
    "category": "method",
    "text": "version()\n\nReturns the current Garamond version using the Project.toml and git. If the Project.toml, git are not available, the version defaults to an empty string.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.web_socket_server-Tuple{UInt16,Channel{String}}",
    "page": "API Reference",
    "title": "Garamond.web_socket_server",
    "category": "method",
    "text": "web_socket_server(port::UInt16, channel::Channel{String})\n\nStarts a bi-directional web socket server that uses a WEB-socket at port port and communicates with the search server through a channel channel.\n\n\n\n\n\n"
},

{
    "location": "api/#",
    "page": "API Reference",
    "title": "API Reference",
    "category": "page",
    "text": "Modules = [Garamond]"
},

]}
