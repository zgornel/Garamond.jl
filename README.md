# Garamond

A small, fast and flexible search engine that supports both classic and semantic searches, written in Julia.

[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md) 
[![Build Status (master)](https://travis-ci.com/zgornel/Garamond.jl.svg?token=8HcgFtAjpxwpdXiu8Fon&branch=master)](https://travis-ci.com/zgornel/Garamond.jl)
[![Build Status (latest)](https://travis-ci.com/zgornel/Garamond.jl.svg?token=8HcgFtAjpxwpdXiu8Fon&branch=latest)](https://travis-ci.com/zgornel/Garamond.jl)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://zgornel.github.io/Garamond.jl/dev)


## Notes
Garamond is under development ...¯\\_(ツ)_/¯. For more information, visit the documentation pages. For any question, praise or remark, contact the author at cornel@oxoaresearch.com


## Future features and TODO's

### Immediate
- ~~Prototype asynchronous search update mechanism for index/search model update based (may require developing `DispatcherCache.jl` first for multi-core support)~~
- ~~Proper API documentation (auto-generated from doc-strings, Documenter.jl)~~
- ~~Take text pre-processing seriously (optimization + flag checking + support skipping patterns from processing)~~
- ~~Support for PDFs, archives, other files (see Taro.jl, TranscodingStreams.jl)~~
- ~~General search engine configuration through runconfig file i.e. `~/.garamondrc`~~
- ~~Websocket support for server~~ **WIP**
- ~~HTTP client~~ **WIP**
- Fat binary compilation (binaries for server and clients)
- Take testing seriously

### Longer term
- Add support for controlling webcrawlers
- Develop web crawler
- Implement HSNW heuristic search (cluster analysis)
- Reliable search from any language to any language (external APIs?, dictionaries ?)
- Abstract semantic search (search into 1-D, 2-D signals i.e. sound, images)
- Ontology builder and explorer; (see [Conceptnet](https://github.com/commonsense/conceptnet5)); arbitrary query to target ontology linking
- P2P
- [Flux.jl](https://github.com/FluxML/Flux.jl) native embedding generation (i.e. custom embedding generation model architectures)


## Installation
Check out the documentation for details on howto install Garamond.


## License
This code has an MIT license and therefore it is free.


## References
No references so far :)
