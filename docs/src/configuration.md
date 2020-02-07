# Configuration

The configuration options of the Garamond search engine can be logically split into three main categories, based on what is configured and where the options actually reside:

- **indexing and search** - this configuration pertains to the way the data loaded, indexed and searched. In this category one can count options such as the type of search being performed, the path to the actual files to be indexed, the specific parser to use, the path and type of embeddings libraries to be used for semantic search and so on. The data configuration format is a simple JSON file.

- **search engine** - the engine configuration file is a simple run-control file named `.garamondrc` that has to reside in the user home directory on UNIX-like systems i.e. `~/.garamondrc`. The configuration file is parsed entirely as Julia code at the startup of the search server - if the file exists - and pre-compiled into the engine itself. The file defines options that pertain to external programs such as the pdf to text converter and replacement values for several default internal variables of the engine such as how many search results to return by default, the [maximum edit distance](https://en.wikipedia.org/wiki/Edit_distance) to be used when searching for suggestions for possibly misspelled query terms and so on.

- **internal** - it is made of the default values for various parameters as well as necessary constants such as text preprocessing flags. These defaults are found in `src/config/defaults.jl` and can be modified prior to running the search server.

## Data configuration

!!! warning "Missing data configuration options"

    For a developers view on the usage of the data configuration options, check the sample [configuration files](https://github.com/zgornel/Garamond.jl/tree/master/test/configs) and the [data configuration parser](https://github.com/zgornel/Garamond.jl/blob/master/src/searchable/config_parser.jl).
    It is important to note that some of these options may change quite frequently as the engine is under heavy development w.r.t. the data API.

## Engine configuration

A sample `~/.garamondrc` file with all available configuration options filled would look like:
```julia
# Text to pdf program
const PDFTOTEXT_PROGRAM = "/bin/pdftotext"

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
