```@meta
CurrentModule=Garamond
```

# Introduction

Garamond is a small, flexible search engine. It can be used both as a Julia package, with search functionality available through API method calls, as well as a standalone search server with search functionality accessible through clients that send queries and receive search results to and from the server.

Internally, the engine's architecture is that of an ensemble of searchers, each with its own characteristics i.e. indexed data fields, preprocessing options etc. whose individual search results can be combined in a variety of ways. The searchers can perform either classical search i.e. based on word-statistics or semantic search i.e. based on word embeddings.

## Installation

### Git cloning
The `Garamond` repository can be downloaded through git:
```
$ git clone https://github.com/zgornel/Garamond.jl
```

### Julia REPL
The repository can also be downloaded from inside Julia. Entering the Pkg mode with `]` and writing:
```
add https://github.com/zgornel/Garamond.jl#master
```
downloads the `master` branch of the repository and adds `Garamond` to the current active environment.
