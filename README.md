# Garamond

A small corpus search engine written in Julia.

[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md) 
[![Build Status (master)](https://travis-ci.com/zgornel/Garamond.jl.svg?token=8HcgFtAjpxwpdXiu8Fon&branch=master)](https://travis-ci.com/zgornel/Garamond.jl)
[![Build Status (latest)](https://travis-ci.com/zgornel/Garamond.jl.svg?token=8HcgFtAjpxwpdXiu8Fon&branch=latest)](https://travis-ci.com/zgornel/Garamond.jl)


## Introduction

Garamond is under development ...¯\\_(ツ)_/¯

For more information, please leave a message at cornel@oxoaresearch.com


## Feature list
    - Document Indexing/Modelling:
        - [x] Sigle delimited file (rows are documents)
        - [x] A directory (all files in all subdirs that fit a globbing pattern are indexed)
        - [x] Summarization support (index [TextRank](https://en.wikipedia.org/wiki/Automatic_summarization#Unsupervised_approach:_TextRank)-based summary)
        - [ ] Parallelism: green light or hardware threads **TODO**
        - [ ] Update support (real-time, once-every-x) **TODO**
        - File support:
            - [x] Text files
            - [ ] Compressed files **TODO**
            - [ ] PDF files **TODO**
            - [ ] Microsoft like (.doc, .xls etc)
    - Engine configuration:
        - [x] Multiple corpora data configurations in one file
        - [ ] Individual corpus data configuration
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
            - [ ] Socket **TODO**
            - [ ] Streams **TODO**
        - Embedding training
            - [x] Word2Vec
            - [ ] Conceptnet **TODO?**
            - [ ] GloVe **TODO?**
        - Parallelism
            - [x] Multi-threading (each corpus is searched withing a hardware thread)
            - [ ] Multi-core + task scheduling ([Dispatcher.jl](https://github.com/invenia/Dispatcher.jl) for distributed corpora **TODO**
            - [ ] Cluster support **TODO**


## Immediate TODOs
- Prototype asynchronous search update mechanism for index/search model update based (may require developing `DispatcherCache.jl` first for multi-core support)
- Support for PDFs, archives, other files (see Taro.jl, TranscodingStreams.jl)
- Stream and socket IO
- Minimal command line interface: options for configs, I/O types, logging, parallelism(?)
- Proper API documentation (auto-generated from doc-strings, Documenter.jl?)
- Minimalistic HTTP server (new package GaramondHTTPServer.jl ?)
- Take text pre-processing seriously (optimization + flag checking + support skipping patterns from processing)
- Take testing seriously
- Fat binary compilation (i.e. have one binary for the whole search engine, including dependencies)


## Longer term plans
- Implement HSNW heuristic search (cluster analysis)
- Reliable search from any language to any language (external APIs?, dictionaries ?)
- Abstract semantic search (search into 1-D, 2-D signals i.e. sound, images)
- Ontology builder and explorer; (see [Conceptnet](https://github.com/commonsense/conceptnet5)); arbitrary query to target ontology linking
- P2P
- [Flux.jl](https://github.com/FluxML/Flux.jl) native embedding generation (i.e. custom embedding generation model architectures)


## Notes
The following exports: `OPENBLAS_NUM_THREADS=1` and `JULIA_NUM_THREADS=<n>` have to be performed for multi-threading to work efficiently.
