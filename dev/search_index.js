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
    "text": "Garamond is a small, flexible search engine. It can be used both as a Julia package, with search functionality available through API method calls, as well as a standalone search server with search functionality accessible through clients that send queries and receive search results to and from the server.Internally, the engine\'s architecture is that of an ensemble of searchers, each with its own characteristics i.e. indexed data fields, preprocessing options etc. whose individual search results can be combined in a variety of ways. The searchers can perform either classical search i.e. based on word-statistics or semantic search i.e. based on word embeddings."
},

{
    "location": "#Installation-1",
    "page": "Introduction",
    "title": "Installation",
    "category": "section",
    "text": ""
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
    "text": "The repository can also be downloaded from inside Julia. Entering the Pkg mode with ] and writing:add https://github.com/zgornel/Garamond.jl#masterdownloads the master branch of the repository and adds Garamond to the current active environment."
},

{
    "location": "simple_example/#",
    "page": "Simple example",
    "title": "Simple example",
    "category": "page",
    "text": ""
},

{
    "location": "simple_example/#Simple-usage-example-1",
    "page": "Simple example",
    "title": "Simple usage example",
    "category": "section",
    "text": ""
},

{
    "location": "simple_example/#Classic-search-1",
    "page": "Simple example",
    "title": "Classic search",
    "category": "section",
    "text": "The following code snippet runs a quick and dirty search:# Use packages\nusing Pkg;\nPkg.activate(\".\");\nusing Garamond\n\n# Load searchers\nfilepath = [\"/home/zgornel/projects/extras_for_Garamond/data/Cornel/delimited/config_cornel_data_classic.json\"]\nsrchers = load_searchers(filepath);\n\n# Search\nQUERY = \"arthur clarke pattern\"\nresults = search(srchers, QUERY)The search results promptly appear:# 2-element Array{SearchResult,1}:\n#  Search results for id=\"biglib-classic\":  7 hits, 2 query terms, 0 suggestions.\n#  Search results for id=\"techlib-classic\":  2 hits, 1 query terms, 0 suggestions.To view them in a more detailed fashion i.e. including metadata, one can run:print_search_results(srchers, results)which prints:# 9 search results from 2 corpora\n# `-[id=\"biglib-classic\"] 7 search results:\n#   2.9344456 ~ 1-[\"The last theorem\" by Arthur C. Clarke, 2008 (2010)]\n#   2.5842855 ~ 2-[\"2010: odyssey two\" by Arthur C. Clarke, 1982 (2010)]\n#   2.059056 ~ 4-[\"Childhood\'s end\" by Arthur C. Clarke, 1954 (2013)]\n#   2.059056 ~ 6-[\"3001: the final odyssey\" by Arthur C. Clarke, 1968 (1997)]\n#   2.059056 ~ 7-[\"2061: odyssey three\" by Arthur C. Clarke, 1987 (1988)]\n#   1.8586512 ~ 3-[\"The city and the stars\" by Arthur C. Clarke, 1956 (2003)]\n#   1.8586512 ~ 5-[\"2001: a space odyssey\" by Arthur C. Clarke, 1968 (2001)]\n# `-[id=\"techlib-classic\"] 2 search results:\n#   0.6101619 ~ 3-[\"Pattern recognition 4\'th edition\" by Sergios Theodoridis, Konstantinos Koutroumbas, 2008 (2008)]\n#   0.37574464 ~ 2-[\"Pattern classification, 2\'nd edition\" by Richard O. Douda, Peter E. Hart, David G. Stork, 2000 (2000)]"
},

{
    "location": "simple_example/#Semantic-search-1",
    "page": "Simple example",
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
    "text": "The configuration options of the Garamond search engine can be logically split into three main categories, based on what is configured nd where the options actually reside:indexing and search - this configuration pertains to the way the data is indexed and the type of search it supports. In this category one can count options such as the type of search being performed, the path to the actual files to be indexed, the specific parser to use, the path and type of embeddings libraries to be used for semantic search and so on. The data configuration format is a simple JSON file in which multiple configurations for the same or distinct datasets can reside. The engine supports loading multiple such configuration files, providing additional flexibility to the user in choosing how to construct the search structures that guide the search given the particularities of their data. One could for example perform several searches using in the same data or a single search on several distinct datasets.\nsearch engine - the engine configuration file is a simple run-control file named .garamondrc that has to reside in the user home directory on UNIX-like systems i.e. ~/.garamondrc. The configuration file is parsed entirely as Julia code at the startup of the search server - if the file exists - and pre-compiled into the engine itself. The file defines options that pertain to external programs such as the pdf to text converter and replacement values for several default internal variables of the engine such as what type of StringAnalysis document objects the documents are internally represented as, how many search results to return by default, the maximum edit distance to be used when searching for suggestions for possibly misspelled query terms and so on.\ninternal - the engine default configuration variable values for as well as necessary constants such as text preprocessing flags (a flag describes a full set of operations to be performed on input text) reside in the src/config/defaults.jl file and can be modified prior to running the search server. Please note that such operation will also result in new compilation of the package."
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
    "text": "A sample ~/.garamondrc file with all available configuration options filled would look like:# Text to pdf program\nconst PDFTOTEXT_PROGRAM = \"/bin/pdftotext\"\n\n# Type of StrinAnalysis document\nconst DOCUMENT_TYPE = StringAnalysis.NGramDocument{String}\n\n# Maximum edit distance for suggestion search\nconst MAX_EDIT_DISTANCE = 2\n\n# Default maximum matches to return\nconst MAX_MATCHES = 1_000\n\n# Default maximum number of suggestions to return\n# for each non-matched query term when squashing\n# results from several corpora\nconst MAX_SUGGESTIONS = 10\n\n# Default approach to combine the retrieved document\n# scores from multiple searchers\nconst RESULT_AGGREGATION_STRATEGY = :mean"
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
    "location": "clientserver/#Search-server-and-clients-1",
    "page": "Client/Server",
    "title": "Search server and clients",
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
    "text": "The commandline client garc sends the query to an open Unix socket and waits the search results on the same socket. It is worthwhile checking the available commandline options:$ ./garc --help\nusage: garc [--log-level LOG-LEVEL] [-u UNIX-SOCKET] [--pretty]\n            [--max-matches MAX-MATCHES] [--search-type SEARCH-TYPE]\n            [--search-method SEARCH-METHOD]\n            [--max-suggestions MAX-SUGGESTIONS] [-k] [-h] [query]\n\npositional arguments:\n  query                 the search query (default: \"\")\n\noptional arguments:\n  --log-level LOG-LEVEL\n                        logging level (default: \"warn\")\n  -u, --unix-socket UNIX-SOCKET\n                        UNIX socket for data communication (default:\n                        \"\")\n  --pretty              output is a pretty print of the results\n  --max-matches MAX-MATCHES\n                        maximum results to return (type: Int64,\n                        default: 10)\n  --search-type SEARCH-TYPE\n                        where to search (type: Symbol, default:\n                        :metadata)\n  --search-method SEARCH-METHOD\n                        type of match done during search (type:\n                        Symbol, default: :exact)\n  --max-suggestions MAX-SUGGESTIONS\n                        How many suggestions to return for each\n                        mismatched query term (type: Int64, default:\n                        0)\n  -k, --kill            Kill the search engine server\n  -h, --help            show this help message and exitAssuming that a search server was started with$ ./gars -d ../extras_for_Garamond/data/Cornel/delimited/config_cornel_data_semantic.json -u /tmp/_garamond_socket_001 --log-level infothe following example performs a query using the server defined above and displays the results in a human readable way:$ ./garc \"paolo coelho\" -u /tmp/_garamond_socket_001 --max-matches 5 --pretty --log-level debug\n┌ Debug: ~ GARAMOND~ (unix-socket client)\n└ @ Main.GaramondCLIClient ~/projects/Garamond.jl/garc:134\n┌ Debug: >>> Request sent.\n└ @ Main.GaramondCLIClient ~/projects/Garamond.jl/garc:62\n┌ Debug: <<< Search results received.\n└ @ Main.GaramondCLIClient ~/projects/Garamond.jl/garc:64\n10 search results from 2 corpora\n`-[id=\"biglib-semantic\"] 5 search results:\n  0.9740912108947957 ~ 50-[\"The tunnel\" by Ernesto Sabato, 1948 (2004)]\n  0.9598814147037482 ~ 63-[\"The autumn of the patriarch\" by Gabriel Garcia Marquez, 1975 (2005)]\n  0.9417322045431806 ~ 48-[\"Dialogues\" by Louis Borges, Ernesto Sabato, 1976 (2005)]\n  0.9380608114354404 ~ 49-[\"Essays\" by Ernesto Sabato, 1996 (2005)]\n  0.9262495410707653 ~ 61-[\"The green house\" by Mario Vargas Llosa, 1965 (2008)]\n`-[id=\"techlib-semantic\"] 5 search results:\n  0.8118677136424433 ~ 3-[\"Pattern recognition 4\'th edition\" by Sergios Theodoridis, Konstantinos Koutroumbas, 2008 (2008)]\n  0.804295301024025 ~ 2-[\"Pattern classification, 2\'nd edition\" by Richard O. Douda, Peter E. Hart, David G. Stork, 2000 (2000)]\n  0.7892832305144111 ~ 4-[\"Artificial intelligence, a modern approach 3\'rd edition\" by Stuart Russel, Peter Norvig, 2009 (2016)]\n  0.7713395077452254 ~ 5-[\"Numerical methods for engineers\" by Steven C. Chapra, Raymond P. Canale, 2014 (2014)]\n  0.7603241404778367 ~ 1-[\"Data classification: algorithms and applications\" by Charu C. Aggarwal, 2014 (2014)]\n-----\nElapsed search time: 0.0005221366882324219 seconds.Please not that the search returned five results from each corpus, ordered by relevance. Also, there is are no books by Paolo Coelho in the library (fortunately). The time indicated is from a second run of the query, the first query runs always takes longer (~1s) as the code needs to be compiled on-the-fly."
},

{
    "location": "clientserver/#Web-client-1",
    "page": "Client/Server",
    "title": "Web client",
    "category": "section",
    "text": "The web client garw starts a HTTP server that locally serves a page: it is the page that has to actually connect to the search server through a user-specified web-socket. Therefore, garw is technically not fully a client but for the sake of consistency we will consider it to be one. Its commandline arguments are more simplistic:$ ./garw --help\nusage: garw [--log-level LOG-LEVEL] [-w WEB-SOCKET-PORT]\n            [-p HTTP-PORT] [--web-page WEB-PAGE] [-h]\n\noptional arguments:\n  --log-level LOG-LEVEL\n                        logging level (default: \"warn\")\n  -w, --web-socket-port WEB-SOCKET-PORT\n                        WEB socket data communication port (type:\n                        UInt16, default: 0x0000)\n  -p, --http-port HTTP-PORT\n                        HTTP port for the http server (type: Int64,\n                        default: 8888)\n  --web-page WEB-PAGE   Search web page to serve\n  -h, --help            show this help message and exitAssuming a search server is running using a web socket at port 8081 (as in the first gars example above), one can start serving the default webpage at the default port by simply running:$ ./garw -w 8081\n[ Info: Listening on: Sockets.InetAddr{Sockets.IPv4}(ip\"127.0.0.1\", 0x270f)Once a browser opens the page at locahost:8888, output will be generated by garw (by the HTTP.jl module more exactly) regarding the connections occurring:[ Info: Accept (0):  🔗    0↑     0↓    1s 127.0.0.1:8888:8888 ≣16\n┌ Warning: throttling 127.0.0.1\n└ @ HTTP.Servers ~/.julia/packages/HTTP/YjRCz/src/Servers.jl:121\n┌ Info: HTTP.Messages.Request:\n│ \"\"\"\n│ GET /? HTTP/1.1\n│ Host: localhost:8888\n│ Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\n│ User-Agent: mozilla\n│ Upgrade-Insecure-Requests: 1\n│ Accept-Encoding: gzip, deflate\n│ Accept-Language: en-US\n│ Connection: Keep-Alive\n│\n└ \"\"\"From this point on, one can have fun searching using the webpage."
},

{
    "location": "build/#",
    "page": "Building",
    "title": "Building",
    "category": "page",
    "text": ""
},

{
    "location": "build/#Building-1",
    "page": "Building",
    "title": "Building",
    "category": "section",
    "text": "Garamond executables and libraries can be built by running the build/make.jl script. The script has to be run from inside the build directory. It will perform the following operations:check to ensure that it is being ran from the build directory of the Garamond project\ncheck that the source code of the targets is present\ncreate or empty the build output directory\ndownload and install the PackageCompiler and SnoopCompile packages\ndownload and install all project dependencies into the default Julia environment\nbuild the executables and libraries for gars, garc and garw.\nplace the output in the build/bin directory.Note The script will remove the contents of the build/bin directory, removing any previous compilation output.At the end of the compilation process, the build/bin directory will contain:$ tree -L 1 ./build/bin\n./build/bin\n├── cache_ji_v1.0.3\n├── garc\n├── garc.a\n├── garc.so\n├── gars\n├── gars.a\n├── gars.so\n├── garw\n├── garw.a\n└── garw.so\n\n1 directory, 9 filesA sample output of running the script (this output may change in time):$ ./make.jl\n[ Info: Checks complete.\n[ Info: Cleaned up /home/zgornel/projects/Garamond.jl/build/bin.\n[ Info: Dependencies are: [\"SnoopCompile\", \"PackageCompiler\", \"Statistics\", \"Glowe\", \"LightGraphs\", \"Test\", \"Random\", \"StringAnalysis\", \"ConceptnetNumberbatch\", \"NearestNeighbors\", \"HTTP\", \"DelimitedFiles\", \"LinearAlgebra\", \"JSON\", \"DataStructures\", \"Word2Vec\", \"Distances\", \"SparseArrays\", \"Unicode\", \"ProgressMeter\", \"HNSW\", \"BKTrees\", \"Glob\", \"Languages\", \"StringDistances\", \"Dates\", \"Sockets\", \"Logging\", \"ArgParse\"]\n  Updating registry at `~/.julia/registries/General`\n  Updating git-repo `https://github.com/JuliaRegistries/General.git`\n  Updating git-repo `https://github.com/zgornel/Word2Vec.jl`\n  Updating git-repo `https://github.com/zgornel/Distances.jl`\n  Updating git-repo `https://github.com/zgornel/HNSW.jl`\n Resolving package versions...\n  Updating `~/.julia/environments/v1.0/Project.toml`\n [no changes]\n  Updating `~/.julia/environments/v1.0/Manifest.toml`\n [no changes]\n[ Info: Installed dependencies.\n[ Info: *** Building GARS ***\nJulia program file:\n  \"/home/zgornel/projects/Garamond.jl/gars\"\nC program file:\n  \"/home/zgornel/.julia/packages/PackageCompiler/jBqfm/examples/program.c\"\nBuild directory:\n  \"/home/zgornel/projects/Garamond.jl/build/bin\"\nWARNING: could not import Base.endof into StringDistances\n┌ [2019-01-19 21:14:16][WARN][gars:66] At least one data configuration file has to be provided\n└ through the -d option. Exiting...\nAll done\n[ Info: *** Building GARC ***\nJulia program file:\n  \"/home/zgornel/projects/Garamond.jl/garc\"\nC program file:\n  \"/home/zgornel/.julia/packages/PackageCompiler/jBqfm/examples/program.c\"\nBuild directory:\n  \"/home/zgornel/projects/Garamond.jl/build/bin\"\n┌ Warning:  is not a proper UNIX socket. Exiting...\n└ @ Main.GaramondCLIClient ~/projects/Garamond.jl/garc:165\nAll done\n[ Info: *** Building GARW ***\nJulia program file:\n  \"/home/zgornel/projects/Garamond.jl/garw\"\nC program file:\n  \"/home/zgornel/.julia/packages/PackageCompiler/jBqfm/examples/program.c\"\nBuild directory:\n  \"/home/zgornel/projects/Garamond.jl/build/bin\"\n┌ Warning: Wrong web-socket port value 0 (default is 0). Exiting...\n└ @ Main.GaramondWebClient ~/projects/Garamond.jl/garw:74\nAll done\n[ Info: Build complete."
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
    "text": "Using multi-threading in Garamond is not recommended as the feature is still experimental. If one chooses to use multi-threading i.e. through the @threads macro for example, the following steps need to be taken:export the following: OPENBLAS_NUM_THREADS=1 and JULIA_NUM_THREADS=<n> where n is the number of threads desired\nadd the statement Threads.@threads in front of the main for loop of the top search function in src/search.jl (see appropriate comment in the code)warning: Warning\nUsing multi-threading might result in errors and other types of instable behavior. As of the current date (January 2019) seems to be safe. Please make sure you properly check the search behavior prior to running."
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
    "text": "This is a list of the features supported by Garamond.Document indexing\n[x] Summarization support (index TextRank-based summary)\n[x] Basic update or \'re-indexing\' support\n[x] Single file support (parts of the file are treated as documents)\n[x] Multiple files / directory support (a file is a document)\n[x] File format support\n[x] Text formats\n[x] .csv, .tsv etc.\n[x] .json (custom parser must be built)\n[x] .html (custom parser must be built)\n[x] .xml (custom parser must be built)\n[x] Binary formats\n[x] .pdf (through external program pdftotext from libpoppler)\n[ ] Compressed files (.tar, .zip, .gz, etc.)\n[ ] Microsoft new .xml formats(.docx, .xlsx, etc.)\nConfiguration\n[x] Single file for multiple data configurations\n[x] Multiple files for data configurations\n[x] General engine configuration (~/.garamondrc.jl, gets re-compiled into Garamond at startup)\nSearch\nLanguage support\n[x] Uniform language: query language same as doc language\n[ ] Different languages for query / docs (neural vectors only)\nWhere to search\n[x] Document data\n[x] Document metadata\n[x] Document data + metadata\nHow to search for patterns\n[x] exact match\n[x] regular expression (classic vectors only)\nDocument vectors\nClassic vectors\n[x] term counts\n[x] term frequency\n[x] tf-idf\n[x] bm25\nNeural vectors\n[x] Word2Vec\n[x] ConceptnetNumberbatch\n[x] GloVe\nSuggestion support\n[x] BK Trees (through BKTrees.jl)\n[ ] Levenshtein automata\n[ ] SymSpell-like approaches\nLanguage support\n[x] Uniform language: query language same as doc language\n[ ] Different languages for query / docs\nDocument embedding\n[x] Bag of words (neural vectors only)\n[x] SIF (Smooth inverse frequency) (neural vectors only)\n[x] LSA (Latent semantic analysis) (classic vectors only)\n[x] Random projections (classic vectors only)\nVector search models\n[x] Naive i.e. matrix + cosine similarity\n[x] Brute-force \"tree\", uses Euclidean metrics\n[x] KD-tree, uses Euclidean metrics\n[x] HNSW, uses Euclidean metrics\nI/O Iterface\n[x] Server: communication through UNIX/Web sockets\n[x] CLI Client: input and output are STDIN and STDOUT (communication through Unix sockets)\n[x] HTML Client: input and output are in a webpage (communication through Web sockets)\n[x] REST Client: input and output are HTTP requests (communication through the HTTP protocol)\nParallelism forms supported\n[x] Multi-threading (each corpus is searched withing a hardware thread; support is EXPERIMENTAL and it is disabled by default)\nOther\n[x] Caching support for fast operational resumption\n[x] Logging mechanism\n[x] Client/server functionality\n[x] Compilable\n[x] Pretty version support :)The status of the features is as follows:[x] supported\n[ ] planned"
},

{
    "location": "api/#Garamond.SearchConfig",
    "page": "API Reference",
    "title": "Garamond.SearchConfig",
    "category": "type",
    "text": "The search engine configuration object SearchConfig is used in building search objects of type Searcher and to provide information about them to other methods.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.SearchResult",
    "page": "API Reference",
    "title": "Garamond.SearchResult",
    "category": "type",
    "text": "Object that stores the search results from a single searcher.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.Searcher",
    "page": "API Reference",
    "title": "Garamond.Searcher",
    "category": "type",
    "text": "Search object. It contains all the indexed data and related\n\nconfiguration that allows for searches to be performed.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.load_searchers-Tuple{Any}",
    "page": "API Reference",
    "title": "Garamond.load_searchers",
    "category": "method",
    "text": "load_searchers(configs)\n\nLoads/builds searchers using the information provided by configs. The latter can be either a path, a vector of paths to searcher configuration file(s) or a vector of SearchConfig objects.\n\nLoading process flow:\n\nParse configuration files using load_search_configs (if configs contains paths to configuration files)\nThe resulting Vector{SearchConfig} is passed to load_searchers (each SearchConfig contains the data filepath, parameters etc.)\nEach searcher is build using build_searcher and a vector of searcher objects is returned.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.rest_server-Tuple{Integer,Channel{String},Condition}",
    "page": "API Reference",
    "title": "Garamond.rest_server",
    "category": "method",
    "text": "rest_server(port::Integer, channel::Channel{String}, search_server_ready::Condition)\n\nStarts a bi-directional REST server that uses the HTTP port port and communicates with the search server through a channel channel. The server is started once the condition search_server_ready is triggered.\n\nService GET link formats:\n\nsearch: /api/v1/search/<max_matches>/<search_method>/<max_suggestions>          /<what_to_return>/<query>/<custom_weights>\nkill server: /api/v1/kill\nread configs: /api/v1/read-configs\n\nwhere:     <maxmatches> is a number larger than 0     <searchmethod> can be exact or regex     <maxsuggestions> is a number larger of equal to 0     <whattoreturn> can be json-index or json-data     <query> can be any string (%20 acts as space)     <customweights> custom weights for the searchers\n\nExamples:\n\n`http://localhost:9001/api/v1/search/100/exact/0/json-index/something%20to%20search`\n`http://localhost:9001/api/v1/search/100/regex/3/json-index/something%20to%20search/searcher1_0.1`\n`http://localhost:9001/api/v1/read-configs`\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.search-Union{Tuple{A}, Tuple{E}, Tuple{NaiveIndex{E,A},AbstractArray{T,1} where T,Int64}, Tuple{NaiveIndex{E,A},AbstractArray{T,1} where T,Int64,Array{Int64,1}}} where A<:AbstractArray{E,2} where E<:AbstractFloat",
    "page": "API Reference",
    "title": "Garamond.search",
    "category": "method",
    "text": "search(index, point, k)\n\nSearches for the k nearest neighbors of point in data contained in the index. The index may vary from a simple wrapper inside a matrix to more complex structures such as k-d trees, etc.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.search-Union{Tuple{I}, Tuple{E}, Tuple{D}, Tuple{T}, Tuple{Searcher{T,D,E,I},Any}} where I<:AbstractIndex where E where D<:StringAnalysis.AbstractDocument where T<:AbstractFloat",
    "page": "API Reference",
    "title": "Garamond.search",
    "category": "method",
    "text": "search(srcher, query [;kwargs])\n\nSearches for query (i.e. key terms) in srcher, and returns information regarding the the documents that match best the query. The function returns an object of type SearchResult.\n\nArguments\n\nsrcher::Searcher is the corpus searcher\nquery the query, can be either a String or Vector{String}\n\nKeyword arguments\n\nsearch_method::Symbol controls the type of matching: :exact  searches for the very same string while :regex searches for a string  in the corpus that includes the needle\nmax_matches::Int is the maximum number of search results to return\nmax_suggestions::Int is the maximum number of suggestions to return for  each missing needle\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.search-Union{Tuple{T}, Tuple{Array{#s347,1} where #s347<:(Searcher{T,D,E,I} where I<:AbstractIndex where E where D<:AbstractDocument),Any}} where T<:AbstractFloat",
    "page": "API Reference",
    "title": "Garamond.search",
    "category": "method",
    "text": "search(srchers, query [;kwargs])\n\nSearches for query (i.e. key terms) in multiple searches and returns information regarding the documents that match best the query. The function returns the search results in the form of a Vector{SearchResult}.\n\nArguments\n\nsrchers::Vector{Searcher} is the searchers vector\nquery the query, can be either a String or Vector{String}\n\nKeyword arguments\n\nsearch_method::Symbol controls the type of matching: :exact  searches for the very same string while :regex searches for a string  in the corpus that includes the needle\nmax_matches::Int is the maximum number of search results to return from  each corpus\nmax_suggestions::Int is the maximum number of suggestions to return for  each missing needle from the search in a corpus\ncustom_weights::Dict{String, Float64} are custom weights for each  searcher\'s results used in result aggregation\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.unix_socket_server-Tuple{AbstractString,Channel{String},Condition}",
    "page": "API Reference",
    "title": "Garamond.unix_socket_server",
    "category": "method",
    "text": "unix_socket_server(socket::AbstractString, channel::Channel{String})\n\nStarts a bi-directional unix socket server that uses a UNIX-socket socket and communicates with the search server through a channel channel. The server is started once the condition search_server_ready is triggered.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.web_socket_server-Tuple{UInt16,Channel{String},Condition}",
    "page": "API Reference",
    "title": "Garamond.web_socket_server",
    "category": "method",
    "text": "web_socket_server(port::UInt16, channel::Channel{String})\n\nStarts a bi-directional web socket server that uses a WEB-socket at port port and communicates with the search server through a channel channel. The server is started once the condition search_server_ready is triggered.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.ERRORED_REQUEST",
    "page": "API Reference",
    "title": "Garamond.ERRORED_REQUEST",
    "category": "constant",
    "text": "Request corresponding to an error i.e. in parsing.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.KILL_REQUEST",
    "page": "API Reference",
    "title": "Garamond.KILL_REQUEST",
    "category": "constant",
    "text": "Request corresponding to a kill server command.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.READCONFIGS_REQUEST",
    "page": "API Reference",
    "title": "Garamond.READCONFIGS_REQUEST",
    "category": "constant",
    "text": "Request corresponding to a searcher read configuration command.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.UNINITIALIZED_REQUEST",
    "page": "API Reference",
    "title": "Garamond.UNINITIALIZED_REQUEST",
    "category": "constant",
    "text": "Default request.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.BruteTreeIndex",
    "page": "API Reference",
    "title": "Garamond.BruteTreeIndex",
    "category": "type",
    "text": "BruteTree index type for storing text embeddings. It is a wrapper around a BruteTree NN structure and performs brute search using a distance-based similarity between vectors.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.HNSWIndex",
    "page": "API Reference",
    "title": "Garamond.HNSWIndex",
    "category": "type",
    "text": "HNSW index type for storing text embeddings. It is a wrapper around a HierarchicalNSW (Hierarchical Navigable Small Worlds) NN graph structure and performs a very efficient search using a distance-based similarity between vectors.\n\nReferences\n\n[Y. A. Malkov, D.A. Yashunin \"Efficient and robust approximate nearest\n\nneighbor search using Hierarchical Navigable Small World graphs\"] (https://arxiv.org/abs/1603.09320)\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.KDTreeIndex",
    "page": "API Reference",
    "title": "Garamond.KDTreeIndex",
    "category": "type",
    "text": "K-D Tree index type for storing text embeddings. It is a wrapper around a KDTree NN structure and performs a more efficient search using a distance-based similarity between vectors.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.NaiveIndex",
    "page": "API Reference",
    "title": "Garamond.NaiveIndex",
    "category": "type",
    "text": "Naive index type for storing text embeddings. It is a wrapper around a matrix of embeddings and performs brute search using the cosine similarity between vectors.\n\n\n\n\n\n"
},

{
    "location": "api/#Base.parse-Tuple{Type{Garamond.SearchServerRequest},AbstractString}",
    "page": "API Reference",
    "title": "Base.parse",
    "category": "method",
    "text": "parse(::Type{SearchServerRequest}, request::AbstractString)\n\nParses a Garamond JSON request received from a client into a SearchServerRequest usable by the search server\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.aggregate!-Union{Tuple{S}, Tuple{T}, Tuple{Array{S,1},Array{StringId,1}}} where S<:SearchResult{T} where T",
    "page": "API Reference",
    "title": "Garamond.aggregate!",
    "category": "method",
    "text": "Aggregates search results from several searchers based on\n\ntheir aggregation_id i.e. results from searchers with identical aggregation id\'s are merged together into a new search result that replaces the individual searcher ones.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.build_corpus-Union{Tuple{T}, Tuple{S}, Tuple{Array{Array{S,1},1},Array{DocumentMetadata,1},Type{T}}} where T<:StringAnalysis.AbstractDocument where S<:AbstractString",
    "page": "API Reference",
    "title": "Garamond.build_corpus",
    "category": "method",
    "text": "build_corpus(documents, metadata_vector, doctype)\n\nBuilds a corpus of documents of type doctype using the data in documents and metadata from metadata_vector.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.build_logger",
    "page": "API Reference",
    "title": "Garamond.build_logger",
    "category": "function",
    "text": "build_logger(logging_stream, log_level)\n\nBuilds a logger using the stream logging_streamand log_level provided.\n\nArguments\n\nlogging_stream::String is the output stream and can take the values:\n\n\"null\" logs to /dev/null, \"stdout\" (default) logs to standard output,   \"/path/to/existing/file\" logs to an existing file and   \"/path/to/non-existing/file\" creates the log file. If no valid option   is provided, the default stream is the standard output.\n\nlog_level::String is the log level can take the values \"debug\",\n\n\"info\", \"error\" and defaults to \"info\" if no valid option is provided.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.build_searcher-Tuple{SearchConfig}",
    "page": "API Reference",
    "title": "Garamond.build_searcher",
    "category": "method",
    "text": "build_searcher(sconf::SearchConfig)\n\nCreates a Searcher from a searcher configuration sconf.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.construct_json_request-Tuple{HTTP.Messages.Request}",
    "page": "API Reference",
    "title": "Garamond.construct_json_request",
    "category": "method",
    "text": "construct_json_request(httpreq::HTTP.Request)\n\nConstructs a Garamond JSON search request from a HTTP request httpreq: extracts the link, parses it, builds the request (in the intermediary representation supported by the search server) and transforms it to JSON.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.construct_json_response-Union{Tuple{C}, Tuple{Any,Any}} where C<:StringAnalysis.Corpus",
    "page": "API Reference",
    "title": "Garamond.construct_json_response",
    "category": "method",
    "text": "construct_json_response(srchers, results, what [; kwargs...])\n\nFunction that constructs a JSON response for a Garamond client using the search results, data from srchers and specifier what.\n\n\n\n\n\n"
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
    "location": "api/#Garamond.link2request-Tuple{AbstractString}",
    "page": "API Reference",
    "title": "Garamond.link2request",
    "category": "method",
    "text": "link2request(link::AbstractString)\n\nTransforms the input HTTP link to a search server request format i.e. a named tuple with specific field names.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.load_search_configs-Tuple{AbstractString}",
    "page": "API Reference",
    "title": "Garamond.load_search_configs",
    "category": "method",
    "text": "load_search_configs(filename)\n\nCreates search configuration objects from a data configuration file specified by filename. The file name can be either an AbstractString with the path to the configuration file or a Vector{AbstractString} specifying multiple configuration file paths. The function returns a Vector{SearchConfig} that is used to build the Searcher objects.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.meta2sv-Union{Tuple{T}, Tuple{T}, Tuple{T,Any}} where T<:StringAnalysis.DocumentMetadata",
    "page": "API Reference",
    "title": "Garamond.meta2sv",
    "category": "method",
    "text": "meta2sv(metadata, fields=DEFAULT_METADATA_FIELDS)\n\nTurns the metadata::DocumentMetadata object\'s fields into a vector of strings, where the value of each field becomes an element in the resulting vector.\n\n\n\n\n\n"
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
    "location": "api/#Garamond.read_searcher_configurations_json-Tuple{Any}",
    "page": "API Reference",
    "title": "Garamond.read_searcher_configurations_json",
    "category": "method",
    "text": "read_searcher_configurations_json(srchers)\n\nReturns a string containing a JSON dictionary where the keys are the paths to the data configuration files for the loaded searchers and the values are the searcher configurations contained in the respective files.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.recursive_glob",
    "page": "API Reference",
    "title": "Garamond.recursive_glob",
    "category": "function",
    "text": "recursive_glob(pattern, path)\n\nGlobs recursively all the files matching the pattern, at the given path.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.search_heuristically!-Union{Tuple{T}, Tuple{S}, Tuple{MultiDict{String,Tuple{T,String}},BKTree{String},Array{S,1}}} where T<:AbstractFloat where S<:AbstractString",
    "page": "API Reference",
    "title": "Garamond.search_heuristically!",
    "category": "method",
    "text": "search_heuristically!(suggestions, search_tree, needles [;max_suggestions=1])\n\nSearches in the search tree for partial matches for each of  the needles.\n\n\n\n\n\n"
},

{
    "location": "api/#Garamond.search_server-Tuple{Any,Any,Any}",
    "page": "API Reference",
    "title": "Garamond.search_server",
    "category": "method",
    "text": "search_server(data_config_paths, io_channel, search_server_ready)\n\nSearch server for Garamond. It is a finite-state-machine that when called, creates the searchers i.e. search objects using the data_config_paths and the proceeds to looping continuously in order to:\n\nupdate the searchers regularly (asynchronously);\nreceive requests from clients on the I/O channel io_channel\ncall search and route responses back to the clients through io_channel\n\nAfter the searchers are loaded, the search server sends a notification using search_server_ready to any listening I/O servers.\n\n\n\n\n\n"
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
    "location": "api/#Garamond.updater-Union{Tuple{Array{S,1}}, Tuple{S}} where S<:Searcher",
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
    "location": "api/#StringAnalysis.embed_document-Union{Tuple{S2}, Tuple{H}, Tuple{T}, Tuple{S1}, Tuple{Union{WordVectors{S1,T,H}, WordVectors{S1,T,H}},Array{S2,1}}} where S2<:AbstractString where H<:Integer where T<:Real where S1<:AbstractString",
    "page": "API Reference",
    "title": "StringAnalysis.embed_document",
    "category": "method",
    "text": "Function that embeds a document i.e. returns an embedding matrix, columns are word embeddings, using the Word2Vec or Glowe WordVectors object. The function has an identical signature as the one from the ConceptnetNumberbatch package.\n\n\n\n\n\n"
},

{
    "location": "api/#StringAnalysis.embed_document-Union{Tuple{T}, Tuple{Union{ConceptNet{#s331,#s330,T} where #s330<:AbstractString where #s331<:Language, WordVectors{#s67,T,#s66} where #s66<:Integer where #s67<:AbstractString, WordVectors{#s329,T,#s68} where #s68<:Integer where #s329<:AbstractString},OrderedDict{String,Int64},Array{String,1}}} where T<:AbstractFloat",
    "page": "API Reference",
    "title": "StringAnalysis.embed_document",
    "category": "method",
    "text": "embed_document(embedder, lexicon, document [;\n               embedding_method=DEFAULT_DOC2VEC_METHOD,\n               isregex=false,\n               sif_alpha=DEFAULT_SIF_ALPHA])\n\nFunction to get from multiple sentences to a document embedding. The embedding_method option controls how multiple sentence embeddings are combined into a single document embedding.\n\nAvalilable options for embedding_method are :bow calculates document embedding as the mean of the sentence embeddings and :sif i.e. smooth-inverse-frequency subtracts paragraph/phrase vector from each sentence embedding.\n\n\n\n\n\n"
},

{
    "location": "api/#",
    "page": "API Reference",
    "title": "API Reference",
    "category": "page",
    "text": "Modules = [Garamond]"
},

]}
