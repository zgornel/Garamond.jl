# Search server, clients and REST APIs

Garamond is designed as a [client-server architecture](http://catb.org/~esr/writings/taoup/html/ch11s06.html#id2958899) in which the server receives requests, performs the search, recommendation or ranking operations and returns the response i.e. results back to the client.

!!! note

    - The clients do not depend on the Garamond package and are very lightweight.
    - The prefered way of communicating with the server is through a REST API using HTTP clients such as [curl](https://curl.haxx.se/), etc.

In the root directory of the package the search server utility and two thin clients can be found:
- **gars** - starts the search server. The operations performed by the search engine server at this point are indexing data according to a given configuration and serving requests coming from connections to sockets or HTTP ports.
- **garc** - command line client supporting Unix socket communication. Through it, a single search can be performed and many of the search request parameters can be specified. It supports printing search results in a human-readable way.
- **garw** - web client supporting Web socket communication (experimental and feature limited). The basic principle is that it starts a HTTP server which serves a page at a given HTTP port. If the web page is not specified, a default one is generated internally and served. The user connects with a web browser of choice at the local address and port (i.e. `127.0.0.1`) and performs the search queries from the page. It naturally supports multiple queries however, the parameters of the search cannot be changed.


## Server
The search server listens on an ip and socket for incoming requests. Once one is received, it is processed and the response sent back to same socket. Looking at the `gars` command line help
```
$ ./gars --help
Activating environment at `~/projects/Garamond.jl/Project.toml`
[ Info: ~ GARAMOND ~ v"0.2.0" commit: 55dd103 (2019-10-23)
usage: gars [-d DATA-CONFIG] [--log-level LOG-LEVEL] [-l LOG]
            [-u UNIX-SOCKET] [-w WEB-SOCKET-PORT]
            [--web-socket-ip WEB-SOCKET-IP] [-p HTTP-PORT]
            [--http-ip HTTP-IP] [-i SEARCH-SERVER-PORT] [-h]

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
  --web-socket-ip WEB-SOCKET-IP
                        WEB socket data communication IP (default:
                        "127.0.0.1")
  -p, --http-port HTTP-PORT
                        HTTP port for REST services (type: Int64)
  --http-ip HTTP-IP     HTTP IP for REST services (default: "0.0.0.0")
  -i, --search-server-port SEARCH-SERVER-PORT
                        Internal TCP port for the search server (type:
                        Int64, default: 9000)
  -h, --help            show this help message and exit
```
starting the server becomes quite straightforward.
For example, to start the server listening to a web socket at port 9100 and to a UNIX socket at `/tmp/some/socket`:
```
$ ./gars -d ./search_data_config.json -u /tmp/some/socket -w 9100 --log-level info
Activating environment at `~/projects/Garamond.jl/Project.toml`
[ Info: • Loaders (custom): sample_loader.jl
[ Info: ~ GARAMOND ~ v"0.2.0" commit: 55dd103 (2019-10-23)
[ [2019-10-19 11:15:55][INFO][sample_loader.jl:179] Sample data loader: read 23269 records from /opt/data/sample
[ [2019-10-19 11:16:11][INFO][search.jl:28] Searchers loaded. Notifying I/O servers...
[ [2019-10-19 11:16:11][INFO][search.jl:34] SEARCH server online @127.0.0.1:9000...
[ [2019-10-19 11:16:11][INFO][unixsocket.jl:30] UNIX-Socket server online @/tmp/some/socket...
[ [2019-10-19 11:16:11][INFO][websocket.jl:21] Web-Socket server online @127.0.0.1:9100...
```
Through the `-d` switch, a data configuration is specified for use. It holds all the necessary information related to data loading, indexing, searching, recommending etc.


## Clients

### garc: Commandline client
The commandline client `garc` sends the request to an open Unix socket and waits the search response on the same socket. It is worthwhile checking the available commandline options:
```
$ ./garc --help
usage: garc [--log-level LOG-LEVEL] [-u UNIX-SOCKET]
            [--return-fields [RETURN-FIELDS...]] [--pretty]
            [--max-matches MAX-MATCHES]
            [--search-method SEARCH-METHOD]
            [--max-suggestions MAX-SUGGESTIONS] [--id-key ID-KEY] [-k]
            [--update-searcher UPDATE-SEARCHER] [--update-all]
            [--rank] [-h] [query]

positional arguments:
  query                 the search query (default: "")

optional arguments:
  --log-level LOG-LEVEL
                        logging level (default: "warn")
  -u, --unix-socket UNIX-SOCKET
                        UNIX socket for data communication (default:
                        "")
  --return-fields [RETURN-FIELDS...]
                        List of fields to return (ignores wrong names)
  --pretty              output is a pretty print of the results
  --max-matches MAX-MATCHES
                        maximum results to return (type: Int64,
                        default: 10)
  --search-method SEARCH-METHOD
                        type of match done during search (type:
                        Symbol, default: :exact)
  --max-suggestions MAX-SUGGESTIONS
                        How many suggestions to return for each
                        mismatched query term (type: Int64, default:
                        0)
  --id-key ID-KEY       The linear ID key (default:
                        "garamond_linear_id")
  -k, --kill            Kill the search engine server
  --update-searcher UPDATE-SEARCHER
                        Update a searcher (default: "")
  --update-all          Update all searchers
  --rank                Use ranker (if any)
  -h, --help            show this help message and exit
```

Assuming that a search server is running and listening at `/tmp/some/socket`, querying the server can be done with:
```
$ ./garc "a test query" -u /tmp/some/socket --max-matches 5 --pretty --return-fields one two three
Elapsed search time: 0.0007750988006591797s.
1/1 search ensemble yielded 5 results.
searcher-1
[0.55555475] ~ one: 4000.0 two: test  three: X15 _linear_id: 15
[0.52799106] ~ one: 2000.0 two: query  three: X42 _linear_id: 42
...
```


### garw: Web-socket client
The web client `garw` starts a HTTP server that locally serves a page: it is the page that has to connect to the search server through a user-specified web-socket. Therefore, `garw` is technically not fully a client but for the sake of consistency we will consider it to be one. Its commandline arguments are more simplistic:
```
$ ./garw --help
usage: garw [--log-level LOG-LEVEL] [-w WEB-SOCKET-PORT]
            [--web-socket-ip WEB-SOCKET-IP] [-p HTTP-PORT]
            [--web-page WEB-PAGE] [--return-fields [RETURN-FIELDS...]]
            [-h]

optional arguments:
  --log-level LOG-LEVEL
                        logging level (default: "warn")
  -w, --web-socket-port WEB-SOCKET-PORT
                        WEB socket data communication port (type:
                        UInt16, default: 0x0000)
  --web-socket-ip WEB-SOCKET-IP
                        WEB socket data communication IP (default:
                        "127.0.0.1")
  -p, --http-port HTTP-PORT
                        HTTP port for the http server (type: Int64,
                        default: 8888)
  --web-page WEB-PAGE   Search web page to serve
  --return-fields [RETURN-FIELDS...]
                        List of fields to return (ignores wrong names)
  -h, --help            show this help message and exit
```
Assuming a search server is running using a web socket at port 9100 (as in the first `gars` example above), one can start serving the default webpage at the default port by simply running:
```
$ ./garw -w 9100
[ Info: ~ GARAMOND ~ (web-socket client)
[ Info: Serving page on 127.0.0.1:8888
```
Using a browser, one can open the page at `locahost:8888` and search.


### HTTP client
A generic HTTP client such as curl can easily be used. Assuming that the search server listens at `localhost:9000`,
```
$curl -d '{<request JSON content>}' -H "Content-Type: application/json" http://localhost:9000/api/search
```
will send a request to the server. The content of the request is a JSON file conforming to the [REST API specification](@ref rest-api-specification).


## [REST API](@id rest-api-specification)
