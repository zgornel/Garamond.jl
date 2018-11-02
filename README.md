# Garamond

A small corpus search engine written in Julia.

[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md) 
[![Build Status (master)](https://travis-ci.com/zgornel/Garamond.jl.svg?token=8HcgFtAjpxwpdXiu8Fon&branch=master)](https://travis-ci.com/zgornel/Garamond.jl)
[![Build Status (latest)](https://travis-ci.com/zgornel/Garamond.jl.svg?token=8HcgFtAjpxwpdXiu8Fon&branch=latest)](https://travis-ci.com/zgornel/Garamond.jl)

## Introduction

Garamond is under development ...¯\\_(ツ)_/¯

For more information, please leave a message at cornel@oxoaresearch.com

## TODOs
- index and search model updating (batch / realtime depending on complexity)
- minimalize memory footprint through: unload corpus data option, single embedding data structure (@cache?), threshold and sparsify embeddings? (view performance impact on this one)
- command line interface
- stream and socket IO
- optimizations
- proper API documentation (auto-generated from doc-strings)
- complete this README.md


## Notes
The following exports: `OPENBLAS_NUM_THREADS=1` and `JULIA_NUM_THREADS=<n>` have to be performed for multi-threading to work efficiently.
