```@meta
CurrentModule=Garamond
```

# Introduction

Garamond is a semantic search engine. Both classical and semantic search are supported. It is designed to be used both as a Julia package, with search functionality available through API method calls, as well as a standalone search server with search functionality accessible through clients that send queries and receive search results to and from the server.

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
This downloads the `master` branch of the repository and adds `Garamond` to the current active environment.
