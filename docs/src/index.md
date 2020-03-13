```@meta
CurrentModule=Garamond
```

!!! warning "Work in progress!"

    The engine is currently under heavy development and the documentation may be slightly out of date. As the API stabilizes, both the content and scope of the present documentation will increase. For any inquiries, bugs or feature requests, be sure to contact the developers or [file an issue](https://github.com/zgornel/Garamond.jl/issues/new).

# Introduction

Garamond is a small, flexible neural and data search engine. It can be used both as a Julia package, with search functionality available through API method calls or as a standalone search server, with search functionality accessible through clients that communicate with the server.

Internally, the engine's architecture is that of an ensemble of searchers, with an analytical database as data backend. Each searcher has its own characteristics i.e. ways of embedding documents, searching through the vectors and the search results from all searchers can be combined in a variety of ways. The engine supports runtime loading and use of custom data loaders, recommendation engines and result rankers.

## Installation

The `Garamond` repository can be downloaded through git:
```
$ git clone https://github.com/zgornel/Garamond.jl
```
or from inside Julia. Entering the Pkg mode with `]` and writing:
```
add https://github.com/zgornel/Garamond.jl#master
```
downloads the `master` branch of the repository and adds `Garamond` to the current active environment.


# Features at a glance

- In-memory analytical db based on [JuliaDB](https://juliadb.org)
- Millon-scale indexing using [hnsw](https://arxiv.org/abs/1603.09320)
- Billion-scale search through [IVFADC](https://github.com/JuliaNeighbors/IVFADC.jl)
- Run-time realtime indexing
- Run-time batch re-indexing
- Complex query search patterns supported
- Pluggable support for custom parsers, loaders, recommenders and rankers
- HTTP(REST)/Web-socket and UNIX socket connectivity
- Wordvectors support: [Word2Vec](https://en.wikipedia.org/wiki/Word2vec), [ConceptnetNumberbatch](https://github.com/commonsense/conceptnet-numberbatch), [GloVe](https://nlp.stanford.edu/projects/glove/)
- Compressed vector support for low-memory footprint using [array quantization](https://github.com/zgornel/QuantizedArrays.jl)
- Classic search based on [term frequency](https://en.wikipedia.org/wiki/Tf%E2%80%93idf#Term_frequency_2), [tf-idf](https://en.wikipedia.org/wiki/Tf%E2%80%93idf#Term_frequency%E2%80%93Inverse_document_frequency), [bm25](https://en.wikipedia.org/wiki/Okapi_BM25)
- Suggestion support using [BK Trees](https://en.wikipedia.org/wiki/BK-tree)
- Many state-of-the-art neural document and sentence embedding methods
- Multi-threading [supported](https://github.com/zgornel/Garamond.jl/tree/cc-multithreading)
- Caching mechanisms for fast resume
- Portable and statically compilable to many architectures

## Coming Soon
- Pool of embedders - searchers can re-use embedders, each searcher can have different input and data embedders

## Longer term plans
- Image/Video/Audio i.e. generic search
- Peer-to-peer / distributed operations support
