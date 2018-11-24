# Garamond

A small corpus search engine written in Julia.

[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md) 
[![Build Status (master)](https://travis-ci.com/zgornel/Garamond.jl.svg?token=8HcgFtAjpxwpdXiu8Fon&branch=master)](https://travis-ci.com/zgornel/Garamond.jl)
[![Build Status (latest)](https://travis-ci.com/zgornel/Garamond.jl.svg?token=8HcgFtAjpxwpdXiu8Fon&branch=latest)](https://travis-ci.com/zgornel/Garamond.jl)


## Introduction

Garamond is under development ...¯\\_(ツ)_/¯

For more information, please leave a message at cornel@oxoaresearch.com


## Feature list

A detailed feature list:

- Document Indexing/Modelling:
    - [x] Single delimited file (rows are documents)
    - [x] A directory (all files in all subdirs that fit a globbing pattern are indexed)
    - [x] Summarization support (index [TextRank](https://en.wikipedia.org/wiki/Automatic_summarization#Unsupervised_approach:_TextRank)-based summary)
    - [ ] Parallelism: green light or hardware threads **TODO**
    - [x] Update support (real-time, once-every-x) **WIP**
    - [x] Multiple files/directories support:
        - [x] Text files
        - [ ] Compressed files **TODO**
        - [ ] PDF files **TODO**
        - [ ] Microsoft/Libre Office files (.doc, .xls etc)
- Engine configuration:
    - [x] Single file for multiple data configurations
    - [x] Multiple files for data configurations
    - [ ] General engine configuration
- Search types:
    - Classic Search:
        - Language support:
            - [x] Uniform language: query language same as doc language
            - [ ] Different languages for query / docs **TODO?**
        - Where to search:
            - [x] data
            - [x] metadata
            - [x] both
        - How to search for patterns:
            - [x] exact match
            - [x] regular expression
        - Document term importance
            - [x] [term frequency](https://en.wikipedia.org/wiki/Tf%E2%80%93idf#Term_frequency_2)
            - [x] [tf-idf](https://en.wikipedia.org/wiki/Tf%E2%80%93idf#Term_frequency%E2%80%93Inverse_document_frequency)
            - [ ] [BM25](https://en.wikipedia.org/wiki/Okapi_BM25) **TODO**
        - Suggestion support
            - [x] [BK Trees](https://en.wikipedia.org/wiki/BK-tree) through [BKTrees.jl](https://github.com/zgornel/BKTrees.jl)
            - [ ] [Levenshtein Automata](https://en.wikipedia.org/wiki/Levenshtein_automaton) **TODO?**
            - [ ] [SymSpell](https://github.com/mammothb/symspellpy) and others **TODO?**
    - Semantic Search:
        - Language support:
            - [x] Uniform language: query language same as doc language (English, German, Romanian)(
            - [x] Different languages for query / docs (**ALMOST** English, German, Romanian; to test :))
        - Where to search:
            - [x] data
            - [x] metadata
            - [x] both
        - Document embedding:
            - [x] Bag of words
            - [x] [Arora et al.](https://openreview.net/pdf?id=SyK00v5xx)
        - Embedding Vector libraries
            - [x] [Word2Vec](https://en.wikipedia.org/wiki/Word2vec) embeddings
            - [x] [ConceptnetNumberbatch](https://github.com/commonsense/conceptnet-numberbatch) embeddings
            - [ ] [GloVe](https://nlp.stanford.edu/projects/glove/) embeddings **TODO?**
            - [ ] Other i.e. [FastText]() **TODO?**
        - Search Models (for semantic vectors)
            - [x] Naive cosine similarity base
            - [x] [Brute-force "tree"](https://en.wikipedia.org/wiki/Brute-force_search) (multiple metrics)
            - [x] [KD-tree](https://en.wikipedia.org/wiki/K-d_tree) (multiple metrics)
            - [x] [HNSW](https://arxiv.org/abs/1603.09320) (multiple metrics supported)
    - I/O Iterface
        - [x] Input: receive query data through UNIX sockets (when in server mode)
        - [x] Output: output to socket (when in server mode), to `STDOUT` when in client mode
    - Per-corpus embedding training
        - [x] Word2Vec (manual)
        - [ ] Conceptnet **TODO?**
        - [ ] GloVe **TODO?**
    - Parallelism forms supported
        - [x] Multi-threading (each corpus is searched withing a hardware thread)
        - [ ] Multi-core + task scheduling ([Dispatcher.jl](https://github.com/invenia/Dispatcher.jl) for distributed corpora **TODO**
        - [ ] Cluster support **TODO**
- Other:
    - [x] Logging mechanism
    - [x] Client/server functionality
    - [x] Pretty version support :)


## Running in server/client mode
- **Server mode**: In _server_ mode, Garamond listens to a socket (i.e.`/tmp/garamond/sockets/socket1`) for incoming queries. Once the query is received, it is processed and the answer written back to same socket.
The following example starts Garamond in server mode (indexes the data and connects to socket, displaying all messages):
```
$ ./garamond.jl --server -d ../extras_for_Garamond/data/Cornel/delimited/config_cornel_data_classic.json -s /tmp/garamond/sockets/socket1 --log-level debug
[ [2018-11-18 15:29:17][DEBUG][garamond.jl:35] ~ GARAMOND ~ v"0.0.0" commit: 90f1a17 (2018-11-20)
[ [2018-11-18 15:29:25][DEBUG][fsm.jl:41] Waiting for query...
```

- **Client mode**: In _client_ mode, the script sends the query to the server's socket and waits the search results on the same socket. Since it uses the whole package, client startup times are slow. View the notes for faster query alternatives. The following example performs a query using the server defined above (the socket is not specified as the server uses the _default_ value):
```
% ./garamond.jl --client --q "arthur c clarke" --log-level debug
[ [2018-11-18 15:37:33][DEBUG][garamond.jl:35] ~ GARAMOND ~ v"0.0.0" commit: 90f1a17 (2018-11-20)
[ [2018-11-18 15:37:33][DEBUG][io.jl:42] >>> Query sent.
[ [2018-11-18 15:37:36][DEBUG][io.jl:44] <<< Search results received.
[{"id":{"id":"biglib-classic"},"query_matches":{"d":{"0.5441896":[3],"0.78605163":[1,2],"0.64313316":[6,7],"0.5895387":[4,5]}},"needle_matches":{"clarke":1.5272124,"arthur":1.5272124,"c":1.5272124},"suggestions":{"d":{}}},{"id":{"id":"techlib-classic"},"query_matches":{"d":{"0.053899456":[1,5]}},"needle_matches":{"c":0.10779891},"suggestions":{"d":{}}}]
```
**Note**: The client mode for `garamond.jl` serves testing purposes only and should not be used in production. A separate client (that just reads and writes to/from the socket) should be developed and readily available.
To view the command line options for `garamond.jl`, run `./garamond.jl --help`:
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


## Immediate TODOs
- ~~Prototype asynchronous search update mechanism for index/search model update based (may require developing `DispatcherCache.jl` first for multi-core support)~~
- Support for PDFs, archives, other files (see Taro.jl, TranscodingStreams.jl)
- Proper API documentation (auto-generated from doc-strings, Documenter.jl?)
- Minimalistic HTTP server (new package GaramondHTTPServer.jl ?)
- ~~Take text pre-processing seriously (optimization + flag checking + support skipping patterns from processing)~~
- Take testing seriously
- Fat binary compilation (i.e. have one binary for the whole search engine, including dependencies)


## Longer term plans
- Implement HSNW heuristic search (cluster analysis)
- Reliable search from any language to any language (external APIs?, dictionaries ?)
- Abstract semantic search (search into 1-D, 2-D signals i.e. sound, images)
- Ontology builder and explorer; (see [Conceptnet](https://github.com/commonsense/conceptnet5)); arbitrary query to target ontology linking
- P2P
- [Flux.jl](https://github.com/FluxML/Flux.jl) native embedding generation (i.e. custom embedding generation model architectures)


## Various Notes
- The following exports: `OPENBLAS_NUM_THREADS=1` and `JULIA_NUM_THREADS=<n>` have to be performed for multi-threading to work efficiently.
- To redirect a TCP socket to a UNIX socket: `socat TCP-LISTEN:<tcp_port>,reuseaddr,fork UNIX-CLIENT:/tmp/unix_socket` or `socat TCP-LISTEN:<tcp_port>,bind=127.0.0.1,reuseaddr,fork,su=nobody,range=127.0.0.0/8 UNIX-CLIENT:/tmp/unix_socket`
- To send a query to a Garamond server (no reply, for debugging purposes): `echo 'find me a needle' | socat - UNIX-CONNECT:/tmp/garamond/sockets/<unix_socket>`
- For interactive send/receive, `socat UNIX-CONNECT:/tmp/garamond/sockets/<unix_socket> STDOUT`
