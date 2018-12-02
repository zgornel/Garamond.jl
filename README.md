# Garamond

A small, fast and flexible search engine that supports both classic and semantic searches, written in Julia.

[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md) 
[![Build Status (master)](https://travis-ci.com/zgornel/Garamond.jl.svg?token=8HcgFtAjpxwpdXiu8Fon&branch=master)](https://travis-ci.com/zgornel/Garamond.jl)
[![Build Status (latest)](https://travis-ci.com/zgornel/Garamond.jl.svg?token=8HcgFtAjpxwpdXiu8Fon&branch=latest)](https://travis-ci.com/zgornel/Garamond.jl)


## Documentation
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://zgornel.github.io/Garamond.jl/dev)


## Notes
Garamond is under development ...¯\\_(ツ)_/¯. For more information, visit the documentation pages. For any question, praise or remark, contact the author at cornel@oxoaresearch.com


## Immediate TODOs
- ~~Prototype asynchronous search update mechanism for index/search model update based (may require developing `DispatcherCache.jl` first for multi-core support)~~
- Support for PDFs, archives, other files (see Taro.jl, TranscodingStreams.jl)
- ~~Proper API documentation (auto-generated from doc-strings, Documenter.jl)~~
- Minimalistic HTTP server (new package GaramondHTTPServer.jl ?)
- ~~Take text pre-processing seriously (optimization + flag checking + support skipping patterns from processing)~~
- Take testing seriously
- Fat binary compilation (i.e. have one binary for the whole search engine, including dependencies)


## Longer term plans
- Add support for controlling webcrawlers
- Develop web crawler
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
