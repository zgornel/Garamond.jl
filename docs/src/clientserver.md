# Running Garamond in server/client mode

Garamond is desinged as a [client-server architecture](http://catb.org/~esr/writings/taoup/html/ch11s06.html#id2958899) in which the server receives queries, performs the search action and returns the results to a client that handles the interaction. The client can be either human or machine controlled.

## Command line utility
The main command line utility for Gramond is the script `garamond.jl` found in the root directory of the package. It is designed to be able to start the search server (i.e. server mode) and to send queries and receive results from the search server (i.e. client mode). The client mode serves testing purposes only and should not be used in production, it will be probably discontinued in the near future. A separate client (that just reads and writes to/from the socket) should be developed and readily available. To view the command line options for `garamond.jl`, run `./garamond.jl --help`:
```
 % ./garamond.jl --help
usage: garamond.jl [-d DATA-CONFIG] [-e ENGINE-CONFIG]
                   [--log-level LOG-LEVEL] [-l LOG] [-s SOCKET]
                   [-q QUERY] [--client] [--server] [-h]

optional arguments:
  -d, --data-config DATA-CONFIG
                        data configuration file
  -e, --engine-config ENGINE-CONFIG
                        search engine configuration file (default: "")
  --log-level LOG-LEVEL
                        logging level (default: "info")
  -l, --log LOG         logging stream (default: "stdout")
  -s, --socket SOCKET   UNIX socket for data communication (default:
                        "/tmp/garamond/sockets/socket1")
  -q, --query QUERY     query the search engine if in client mode
                        (default: "")
  --client              client mode
  --server              server mode
  -h, --help            show this help message and exit
```

## Server mode

In _server_ mode, Garamond listens to a socket (i.e.`/tmp/garamond/sockets/socket1`) for incoming queries. Once the query is received, it is processed and the answer written back to same socket.
The following example starts Garamond in server mode (indexes the data and connects to socket, displaying all messages):
```
$ ./garamond.jl --server -d ../extras_for_Garamond/data/Cornel/delimited/config_cornel_data_classic.json -s /tmp/garamond/sockets/socket1 --log-level debug
[ [2018-11-18 15:29:17][DEBUG][garamond.jl:35] ~ GARAMOND ~ v"0.0.0" commit: 90f1a17 (2018-11-20)
[ [2018-11-18 15:29:25][DEBUG][fsm.jl:41] Waiting for query...
```

##Client mode

In _client_ mode, the script sends the query to the server's socket and waits the search results on the same socket. Since it uses the whole package, client startup times are slow. View the notes for faster query alternatives. The following example performs a query using the server defined above (the socket is not specified as the server uses the _default_ value):
```
% ./garamond.jl --client --q "arthur c clarke" --log-level debug
[ [2018-11-18 15:37:33][DEBUG][garamond.jl:35] ~ GARAMOND ~ v"0.0.0" commit: 90f1a17 (2018-11-20)
[ [2018-11-18 15:37:33][DEBUG][io.jl:42] >>> Query sent.
[ [2018-11-18 15:37:36][DEBUG][io.jl:44] <<< Search results received.
[{"id":{"id":"biglib-classic"},"query_matches":{"d":{"0.5441896":[3],"0.78605163":[1,2],"0.64313316":[6,7],"0.5895387":[4,5]}},"needle_matches":{"clarke":1.5272124,"arthur":1.5272124,"c":1.5272124},"suggestions":{"d":{}}},{"id":{"id":"techlib-classic"},"query_matches":{"d":{"0.053899456":[1,5]}},"needle_matches":{"c":0.10779891},"suggestions":{"d":{}}}]
```
