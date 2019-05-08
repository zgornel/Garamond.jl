# Configuration

The configuration options of the Garamond search engine can be logically split into three main categories, based on what is configured nd where the options actually reside:

- **indexing and search** - this configuration pertains to the way the data is indexed and the type of search it supports. In this category one can count options such as the type of search being performed, the path to the actual files to be indexed, the specific parser to use, the path and type of embeddings libraries to be used for semantic search and so on. The data configuration format is a simple JSON file in which multiple configurations for the same or distinct datasets can reside. The engine supports loading multiple such configuration files, providing additional flexibility to the user in choosing how to construct the search structures that guide the search given the particularities of their data. One could for example perform several searches using in the same data or a single search on several distinct datasets.

- **search engine** - the engine configuration file is a simple run-control file named `.garamondrc` that has to reside in the user home directory on UNIX-like systems i.e. `~/.garamondrc`. The configuration file is parsed entirely as Julia code at the startup of the search server - if the file exists - and pre-compiled into the engine itself. The file defines options that pertain to external programs such as the pdf to text converter and replacement values for several default internal variables of the engine such as what type of [StringAnalysis document objects](https://github.com/zgornel/StringAnalysis.jl) the documents are internally represented as, how many search results to return by default, the [maximum edit distance](https://en.wikipedia.org/wiki/Edit_distance) to be used when searching for suggestions for possibly misspelled query terms and so on.

- **internal** - the engine default configuration variable values for as well as necessary constants such as text preprocessing flags (a flag describes a full set of operations to be performed on input text) reside in the `src/config/defaults.jl` file and can be modified prior to running the search server. Please note that such operation will also result in new compilation of the package.

## Data configuration

This section will be added at a latter time.


## Engine configuration

A sample `~/.garamondrc` file with all available configuration options filled would look like:
```julia
# Text to pdf program
const PDFTOTEXT_PROGRAM = "/bin/pdftotext"

# Type of StrinAnalysis document
const DOCUMENT_TYPE = StringAnalysis.NGramDocument{String}

# Maximum edit distance for suggestion search
const MAX_EDIT_DISTANCE = 2

# Default maximum matches to return
const MAX_MATCHES = 1_000

# Default maximum number of suggestions to return
# for each non-matched query term when squashing
# results from several corpora
const MAX_SUGGESTIONS = 10

# Default approach to combine the retrieved document
# scores from multiple searchers
const RESULT_AGGREGATION_STRATEGY = :mean
```

## Internal configuration

The full internal configuration of the engine can be readily viewed in `src/config/defaults.jl`.
