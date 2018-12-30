# Garamond

A small, fast and flexible semantic search engine, written in Julia.

[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md) 
[![Build Status (master)](https://travis-ci.com/zgornel/Garamond.jl.svg?token=8HcgFtAjpxwpdXiu8Fon&branch=master)](https://travis-ci.com/zgornel/Garamond.jl)
[![Build Status (latest)](https://travis-ci.com/zgornel/Garamond.jl.svg?token=8HcgFtAjpxwpdXiu8Fon&branch=latest)](https://travis-ci.com/zgornel/Garamond.jl)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://zgornel.github.io/Garamond.jl/dev)


## Notes
Garamond is under development ...¯\\_(ツ)_/¯. For more information, visit the documentation pages. For any question, praise or remark, contact the author at cornel@oxoaresearch.com


## Backlog

### Short term
- High priority
    - Fat binary compilation (binaries for server and clients)
    - Take testing seriously
    - Take metadata search seriously (i.e. decide on facets, what fields to use/index etc)
    - Take scoring seriously (build scoring function i.e. normalize document scores, map non-linearly to arbitrary scale; add influence of key-term hit-rate i.e. terms in query found)
- Low priority
    - Improve re-indexing mechanism (i.e. @spawn worker, use incremental approach)
    - Improve speed for suggestions, re-visit mechanism
    - Implement mechanism for query expansion
    - Define (decide on) mechanisms to combine semantic and classic searches (i.e. classic for filtering, semantic for ordering)

### Long term
- Data gathering: web crawler (either implement or support), data streaming sink APIs (should be in distinct support packages)
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
