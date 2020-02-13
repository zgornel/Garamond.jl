# Search server, clients and REST APIs

Garamond is designed as a [client-server architecture](http://catb.org/~esr/writings/taoup/html/ch11s06.html#id2958899) in which the server receives requests, performs the search, recommendation or ranking operations and returns a response containing the search results back to the client.

!!! note

    - The clients do not depend on the Garamond package and are very lightweight.
    - The preferred way of communicating with the server is through the [REST API](@ref rest-api-specification) using HTTP clients such as [curl](https://curl.haxx.se/), etc.

In the root directory of the package the search server utility and two thin clients can be found:
- `gars` - starts the search server. The operations performed by the search engine server at this point are indexing data according to a given configuration and serving requests coming from connections to sockets or HTTP ports.
- `garc` - command line client supporting Unix socket communication. Through it, a single search can be performed and many of the search request parameters can be specified. It supports printing search results in a human-readable way.
- `garw` - web client supporting Web socket communication (experimental and feature limited). The basic principle is that it starts a HTTP server which serves a page at a given HTTP port. If the web page is not specified, a default one is generated internally and served. The user connects with a web browser of choice at the local address and port (i.e. `127.0.0.1`) and performs the search queries from the page. It naturally supports multiple queries however, the parameters of the search cannot be changed.


## Server
The search server listens on an ip and/or socket for incoming requests. Once one is received, it is processed and the response sent back to same socket. Looking at the `gars` command line help
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
            [--response-size RESPONSE-SIZE]
            [--search-method SEARCH-METHOD]
            [--max-suggestions MAX-SUGGESTIONS] [--id-key ID-KEY] [-k]
            [--env-operation ENV-OPERATION ENV-OPERATION]
            [--ranker RANKER] [--input-parser INPUT-PARSER] [-h]
            [query]

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
                        maximum number of results for internal
                        neighbor searches (type: Int64, default: 10)
  --response-size RESPONSE-SIZE
                        maximum number of results to return (type:
                        Int64, default: 10)
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
  --env-operation ENV-OPERATION ENV-OPERATION
                        Environment operation
  --ranker RANKER       The ranker to use; avalilable: noop_ranker
                        (default: "noop_ranker")
  --input-parser INPUT-PARSER
                        The input parser to use; available:
                        noop_input_parser, base_input_parser (default:
                        "noop_input_parser")
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

The REST API exposes the search engine's functionality through HTTP requests. These can be either
`GET` requests (for simple functionality) or `POST` requests, in which the body of the message contains
a correctly formatted [JSON](https://en.wikipedia.org/wiki/JSON) string.

### Endpoints

Assuming a search server listening at `<ip>:<port>`, the exposed API endpoints are:

| operation | HTTP request type |   URI   | description |
| :---      | :---:             | :---    | :---        |
| Search    | `POST`            |`http://<ip>:<port>/api/search` | Searches for a given input in the indexed data |
| Recommend | `POST`            |`http://<ip>:<port>/api/recommend` | Returns a list of similar entities to one specified, using a specified recommender |
| Rank      | `POST`            |`http://<ip>:<port>/api/rank`   | Ranks a given list of ids using a specified ranker |
| Environment-related | `POST`  |`http://<ip>:<port>/api/envop` | Saves, loads or re-indexes a full search environment (data + searchers) |
| Kill      | `GET`             |`http://<ip>:<port>/api/kill` | Kills the  operation|
| Get configuration | `GET`     |`http://<ip>:<port>/api/read-configs` | Returns the data configuration of the engine |

### HTTP status codes
 - `HTTP 200` returned when the request is correct
 - `HTTP 400` returned when the request is malformed
 - `HTTP 501` returned for a wrong URI

### Request body format

The specific functionality of the engine operations i.e. search, ranking is set through parameters passed in the HTTP request body.
The underlying format of the request body is JSON, of the form:
```
{
    "<key>":<value>,
 }
```

The following tables detail the key names, types and default values for each operation supported by the engine.

!!! note
    
    The default values present in the tables below are found in [https://github.com/zgornel/Garamond.jl/blob/master/src/config/defaults.jl](https://github.com/zgornel/Garamond.jl/blob/master/src/config/defaults.jl)

- **Search**

| key             | required |  type  | default | description |
| :---            |  :---:   | :---:  |  :---:  | :---        |
| `query`         |    ✓     | String |    -    | The input query.|
| `input_parser`  |    ✓     | String |    -    | Input parser to use. Available: `"noop_input_parser"` (no specific parsing) and `"base_input_parser"` (constructs data filters and queries).|
| `return_fields` |    ✓     | List of strings |    -    | A list with the names of the database columns to be returned.|
| `search_method` |    -     | String |`DEFAULT_SEARCH_METHOD`| Default search method. Only used by `"search_recommender"`.|
| `searchable_filters` |    -     | List of strings |`<empty list>`| A list of field names whose values will be inserted in the search query if the fields are used for filtering in the query.|
| `max_matches`        |    -     | Integer |`DEFAULT_MAX_MATCHES`  | The maximum number of search results to generate internally from each searcher. Note that still `response_size` recommendations are returned.|
| `response_size`      |    -     | Integer |`DEFAULT_RESPONSE_SIZE`| The maximum number of results to return in the response.|
| `response_page`      |    -     | Integer |`DEFAULT_RESPONSE_PAGE`| Which page of `response_size` results to return in the response.|
| `max_suggestions`    |    -     | Integer |`DEFAULT_MAX_SUGGESTIONS`| The maximum number of suggestions to return for each mismatched keyword of the query.|
| `custom_weights`     |    -     | Dictionary |`DEFAULT_CUSTOM_WEIGHTS`| A dictionary where the keys are strings with searcher ids and the values are weights of the result scores to be used in result aggregation (if the case). In this way, the importance of search results from different searchers can be tuned.|
| `ranker`             |    -     | String  |`DEFAULT_RANKER_NAME`| The name of the ranker. Available: `"noop_ranker"` (no ranking).|

- **Recommend**

| key                  | required |  type  | default | description |
| :---                 |  :---:   | :---:  |  :---:  | :---        |
| `recommender`        |    ✓     | String |    -    | The name of the recommender to use. Available: `"noop_recommender"` (no recommendation) and `"search_recommender"` (search-based recommender).|
| `recommend_id`       |    ✓     | String |    -    | The id of the record for which recommendations (similar items) are sought.|
| `recommend_id_key`   |    ✓     | String |    -    | The database name of the column holding the recommend id.|
| `input_parser`       |    ✓     | String |    -    | Input parser to use. Available: `"noop_input_parser"` (no specific parsing) and `"base_input_parser"` (constructs data filters and queries). The `"base_input_parser"` has to be used with `"search_recommender"`.|
| `filter_fields`      |    ✓     | List of strings |    -    | Contains the names of the fields that will be used by the recommender. Only used in `"search_recommender"`.|
| `return_fields`      |    ✓     | List of strings |    -    | A list with the names of the database columns to be returned.|
| `search_method`      |    -     | String |`DEFAULT_SEARCH_METHOD`| Default search method. Only used by `"search_recommender"`.|
| `searchable_filters` |    -     | List of strings |`<empty list>`| A list of field names whose values will be inserted in the search query sent to the searchers, if the field names appear also in `filter_fields`. This guarantees a better match between results returned by querying the database (filtering) and the indexed data (search).|
| `max_matches`        |    -     | Integer |`DEFAULT_MAX_MATCHES`  | The maximum number of recommendations to generate internally. Note that still `response_size` recommendations are returned.|
| `response_size`      |    -     | Integer |`DEFAULT_RESPONSE_SIZE`| The maximum number of results to return in the response.|
| `response_page`      |    -     | Integer |`DEFAULT_RESPONSE_PAGE`| Which page of `response_size` results to return in the response.|
| `ranker`             |    -     | String  |`DEFAULT_RANKER_NAME`| The name of the ranker. Available: `"noop_ranker"` (no ranking).|

- **Rank**

| key             | required |  type   | default | description |
| :---            |  :---:   | :---:   |  :---:  | :---        |
| `ranker`        |    ✓     | String  |    -    | The name of the ranker. Available: `"noop_ranker"` (no ranking).|
| `rank_ids`      |    ✓     | List of strings |    -    | The ids to be ranked.|
| `rank_id_key`   |    ✓     | String  |    -    | The database name of the column holding the ids to be ranked.|
| `return_fields` |    ✓     | List of strings |    -    | A list with the names of the database columns to be returned.|
| `response_size` |    -     | Integer |`DEFAULT_RESPONSE_SIZE`| The maximum number of results to return in the response.|
| `response_page` |    -     | Integer |`DEFAULT_RESPONSE_PAGE`| Which page of `response_size` results to return in the response.|

- **Environment-related**

| key            | required |  type  | default | description |
| :---           |  :---:   | :---:  |  :---:  | :---        |
| `cmd`          |    ✓     | String |    -    | The operation being performed. Available: `"load"`, `"save"` and `"reindex"`.|
| `cmd_argument` |    ✓     | String |    -    | Argument of the operation. For `"load"` and `"save"` it should be a filepath, for `"reindex"`, the searcher id or `*`.|

- **Kill**

No parameters needed.

- **Get configuration**

No parameters needed.

### Response format

If the search, recommendation and ranking requests are successful a HTTP response with status code 200 is received. The body of the HTTP response message is a JSON string representing the actual results of the operation.
Its keys and values are detailed below:

| key                     |  type  | description |
| :---                    | :---:  | :---        |
| `n_searchers`           | Integer | The total number of searchers.|
| `n_searchers_w_results` | Integer | The total number of searchers that returned data.|
| `suggestions`           | Dictionary | A dictionary containing for each searcher, a list of suggestions for each missing token.|
| `elapsed_time`          | Float | The time elapsed in executing the request, except for the building of results.|
| `results`               | Dictionary | A dictionary containing for each searcher a list of dictionaries, each of the latter containing individual result data. For filtering operations, a random id is generated to which the list of results is associated.|
| `n_total_results`       | Integer | The total number of results returned by the engine.|

For more information on how the internal [engine result structure](https://github.com/zgornel/Garamond.jl/blob/master/src/search/results.jl) is used to construct the JSON output, consult the [`build_response`](https://github.com/zgornel/Garamond.jl/blob/master/src/server/search.jl) function.
