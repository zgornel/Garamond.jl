# Running Garamond in server/client mode

Garamond is designed as a [client-server architecture](http://catb.org/~esr/writings/taoup/html/ch11s06.html#id2958899) in which the server receives queries, performs the search action and returns the results to a client that handles the interaction. The client can be either human or machine controlled. There are three utilities designed to handle the search process, all of which can be found in the root directory of the package:
- **gars** - starts the search server. The operations performed by the search engine server at this point are indexing data at a given location and listening to a socket.
- **garc** - command line client supporting Unix socket communication. It is the most feature complete of the two clients. Through it, a single search can be performed and all search parameters can be specified. It supports pretty printing as well as a means of visually investigating the results of the search.
- **garw** - web client supporting Web socket communication (EXPERIMENTAL). The basic principle is that the client starts a HTTP server which serves a page at a given HTTP port. If the web page is not specified, a default one is generated internally and served. The user connects with a web browser of choice at the local address (i.e. `127.0.0.1`) and specified port and performs the search queries from the page. It naturally supports multiple queries however, the parameters of the search cannot be changed.

Notes:
- The clients do not depend on the Garamond package and are very lightweight.
- In the future, **garw** should support a query format through which the types of searches and their parameters can be controlled. Such options can include performing exact or regex matches, the number of maximum results to return etc.
- The clients are currently the only 'easy' way to communicate with the search server; communication with the latter is pretty straightforward (i.e. reading and writing from sockets) as long as the JSON format for data communication is respected.


## Starting the search server
The search server listens to a socket for incoming queries. Once the query is received, it is processed and the answer written back to same socket. Looking at the `gars` utility help
```
$ ./gars --help
usage: gars -d DATA-CONFIG [--log-level LOG-LEVEL] [-l LOG]
            [-u UNIX-SOCKET] [-w WEB-SOCKET-PORT] [-h]

optional arguments:
  -d, --data-config DATA-CONFIG
                        data configuration file
  --log-level LOG-LEVEL
                        logging level (default: "info")
  -l, --log LOG         logging stream (default: "stdout")
  -u, --unix-socket UNIX-SOCKET
                        UNIX socket for data communication
  -w, --web-socket-port WEB-SOCKET-PORT
                        WEB socket data communication port (type:
                        UInt16)
  -h, --help            show this help message and exit
```
starting the server becomes quite straightforward. To start the server listening to a web socket at port 8081, all one has to do is:
```
$ ./gars -d ../extras_for_Garamond/data/Cornel/delimited/config_cornel_data_semantic.json -w 8081 --log-level info
[ [2018-12-18 12:26:59][INFO][servers.jl:102] ~ GARAMOND ~ v"0.0.0" commit: 4d7be0d (2018-12-07)
[ [2018-12-18 12:27:21][INFO][servers.jl:25] I/O: Waiting for data @web-socket:8081...
[ [2018-12-18 12:27:22][INFO][Servers.jl:301] Listening on: Sockets.InetAddr{Sockets.IPv4}(ip"127.0.0.1", 0x1f91)
```
Notice that the `-d` switch allows indicating a data configuration to use. Multiple such configurations can be provided if multiple data sources are to be handled. After running the command, information-level output of the server is being written to the standard output stream. To write directly the server logs to a file, a file can be indicated through the `-log` switch or the output redirected to a file.


## Commandline client
The commandline client `garc` sends the query to an open Unix socket and waits the search results on the same socket. It is worthwhile checking the available commandline options:
```
$ ./garc --help
usage: garc [--log-level LOG-LEVEL] [-u UNIX-SOCKET] [--pretty]
            [--max-matches MAX-MATCHES] [--search-type SEARCH-TYPE]
            [--search-method SEARCH-METHOD]
            [--max-suggestions MAX-SUGGESTIONS] [-k] [-h] [query]

positional arguments:
  query                 the search query (default: "")

optional arguments:
  --log-level LOG-LEVEL
                        logging level (default: "warn")
  -u, --unix-socket UNIX-SOCKET
                        UNIX socket for data communication (default:
                        "")
  --pretty              output is a pretty print of the results
  --max-matches MAX-MATCHES
                        maximum results to return (type: Int64,
                        default: 10)
  --search-type SEARCH-TYPE
                        where to search (type: Symbol, default:
                        :metadata)
  --search-method SEARCH-METHOD
                        type of match done during search (type:
                        Symbol, default: :exact)
  --max-suggestions MAX-SUGGESTIONS
                        How many suggestions to return for each
                        mismatched query term (type: Int64, default:
                        0)
  -k, --kill            Kill the search engine server
  -h, --help            show this help message and exit
```

Assuming that a search server was started with
```
$ ./gars -d ../extras_for_Garamond/data/Cornel/delimited/config_cornel_data_semantic.json -u /tmp/_garamond_socket_001 --log-level info
```
the following example performs a query using the server defined above and displays the results in a human readable way:
```
$ ./garc "paolo coelho" -u /tmp/_garamond_socket_001 --max-matches 5 --pretty --log-level debug
┌ Debug: ~ GARAMOND~ (unix-socket client)
└ @ Main.GaramondCLIClient ~/projects/Garamond.jl/garc:134
┌ Debug: >>> Request sent.
└ @ Main.GaramondCLIClient ~/projects/Garamond.jl/garc:62
┌ Debug: <<< Search results received.
└ @ Main.GaramondCLIClient ~/projects/Garamond.jl/garc:64
10 search results from 2 corpora
`-[id="biglib-semantic"] 5 search results:
  0.9740912108947957 ~ 50-["The tunnel" by Ernesto Sabato, 1948 (2004)]
  0.9598814147037482 ~ 63-["The autumn of the patriarch" by Gabriel Garcia Marquez, 1975 (2005)]
  0.9417322045431806 ~ 48-["Dialogues" by Louis Borges, Ernesto Sabato, 1976 (2005)]
  0.9380608114354404 ~ 49-["Essays" by Ernesto Sabato, 1996 (2005)]
  0.9262495410707653 ~ 61-["The green house" by Mario Vargas Llosa, 1965 (2008)]
`-[id="techlib-semantic"] 5 search results:
  0.8118677136424433 ~ 3-["Pattern recognition 4'th edition" by Sergios Theodoridis, Konstantinos Koutroumbas, 2008 (2008)]
  0.804295301024025 ~ 2-["Pattern classification, 2'nd edition" by Richard O. Douda, Peter E. Hart, David G. Stork, 2000 (2000)]
  0.7892832305144111 ~ 4-["Artificial intelligence, a modern approach 3'rd edition" by Stuart Russel, Peter Norvig, 2009 (2016)]
  0.7713395077452254 ~ 5-["Numerical methods for engineers" by Steven C. Chapra, Raymond P. Canale, 2014 (2014)]
  0.7603241404778367 ~ 1-["Data classification: algorithms and applications" by Charu C. Aggarwal, 2014 (2014)]
-----
Elapsed search time: 0.0005221366882324219 seconds.
```
Please not that the search returned five results from each corpus, ordered by relevance. Also, there is are no books by `Paolo Coelho` in the library (fortunately). The time indicated is from a second run of the query, the first query runs always takes longer (~1s) as the code needs to be compiled on-the-fly.


## Web client
The web client `garw` starts a HTTP server that locally serves a page: it is the page that has to actually connect to the search server through a user-specified web-socket. Therefore, `garw` is technically not fully a client but for the sake of consistency we will consider it to be one. Its commandline arguments are more simplistic:
```
$ ./garw --help
usage: garw [--log-level LOG-LEVEL] [-w WEB-SOCKET-PORT]
            [-p HTTP-PORT] [--web-page WEB-PAGE] [-h]

optional arguments:
  --log-level LOG-LEVEL
                        logging level (default: "warn")
  -w, --web-socket-port WEB-SOCKET-PORT
                        WEB socket data communication port (type:
                        UInt16, default: 0x0000)
  -p, --http-port HTTP-PORT
                        HTTP port for the http server (type: Int64,
                        default: 8888)
  --web-page WEB-PAGE   Search web page to serve
  -h, --help            show this help message and exit
```
Assuming a search server is running using a web socket at port 8081 (as in the first `gars` example above), one can start serving the default webpage at the default port by simply running:
```
$ ./garw -w 8081
[ Info: Listening on: Sockets.InetAddr{Sockets.IPv4}(ip"127.0.0.1", 0x270f)
```
Once a browser opens the page at `locahost:8888`, output will be generated by `garw` (by the `HTTP.jl` module more exactly) regarding the connections occurring:
```
[ Info: Accept (0):  🔗    0↑     0↓    1s 127.0.0.1:8888:8888 ≣16
┌ Warning: throttling 127.0.0.1
└ @ HTTP.Servers ~/.julia/packages/HTTP/YjRCz/src/Servers.jl:121
┌ Info: HTTP.Messages.Request:
│ """
│ GET /? HTTP/1.1
│ Host: localhost:8888
│ Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
│ User-Agent: mozilla
│ Upgrade-Insecure-Requests: 1
│ Accept-Encoding: gzip, deflate
│ Accept-Language: en-US
│ Connection: Keep-Alive
│
└ """
```
From this point on, one can have fun searching using the webpage.
