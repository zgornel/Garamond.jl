```@meta
CurrentModule=Garamond
```

# Introduction

Garamond is a small, flexible neural and data search engine. It can be used both as a Julia package i.e. search functionality available through API method calls or as a standalone search server i.e. search functionality accessible through clients that communicate with the server.

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

- In-memory analytical data-store based on [JuliaDB](https://juliadb.org)
- Millon-scale indexing using [hnsw](https://arxiv.org/abs/1603.09320)
- Complex query search patterns supported
- Run-time support for custom loaders, recommenders and rankers
- HTTP(REST)/Web-socket and UNIX socket connectivity
- Wordvectors support: [Word2Vec](https://en.wikipedia.org/wiki/Word2vec), [ConceptnetNumberbatch](https://github.com/commonsense/conceptnet-numberbatch), [GloVe](https://nlp.stanford.edu/projects/glove/)
- Classic search based on [term frequency](https://en.wikipedia.org/wiki/Tf%E2%80%93idf#Term_frequency_2), [tf-idf](https://en.wikipedia.org/wiki/Tf%E2%80%93idf#Term_frequency%E2%80%93Inverse_document_frequency), [bm25](https://en.wikipedia.org/wiki/Okapi_BM25)
- Compressed vector support for low-memory footprint
- Suggestion support using [BK Trees](https://en.wikipedia.org/wiki/BK-tree)
- Many state-of-the-art document and sentence embedding methods
- Multi-threading [supported](https://github.com/zgornel/Garamond.jl/tree/cc-multithreading)
- Portable (and statically compilable) to many architectures

## Coming Soon:
- Billion-scale search
- Real-time indexing
- Caching support through serialization for fast operational resumption
