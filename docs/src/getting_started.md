!!! warning "Work in progress!"

    This section currently under construction and is incomplete.

# Getting started

The engine uses a pluggable approach in which data loaders, parsers, recommenders and rankers can be compiled in the engine at runtime. The following usage examples use functionality already provided by the engine. Although by no means exhaustive, it is meant to provide a starting point for exploring the functionality and features of the engine.


!!! tip "Glossary"

    Throughout the documentation, certain terms will appear when refering to the internals of the engine. Some of the most frequent ones are:
    * **configuration** may refer to:
      - searcher configuration, a `SearcherConfig` object which holds the configuration options for individual searchers.
      - environment configuration, a `NamedTuple` that contains searcher configurations as well as other parameters.
      - data configuration file, a JSON file which is parsed to generate an environment configuration.
    * **search environment** a `SearchEnv` object that holds the data and searchers among other. It fully describes the state of the engine.
    * **searcher**, a `Searcher` object that is used to perform the actual search. It holds the indexed documents in some vectorial representation.
    * **index** - the data structure holding the vector representation of the documents.
    * **request** - may refer to:
      - a request form an outside system to the engine i.e. HTTP request.
      - the internal representation of a request, of type `InternalRequest`.

## Engine configuration
The main configuration of the engine pertains to data loading, parsing and indexing. Its role is to provide all necessary details as well as the internal architecture of the engine. The recommended way for configuring the engine is to create a JSON file with all necessary options. Alternatively, the result of parsing the configuration file i.e. the configuration object can be created explicitly however it is, at least at this point, a cumbersome operation.

```@repl_index
using Logging, JSON, JuliaDB, Garamond
include(joinpath(@__DIR__, "..", "..", "test", "configs", "configgenerator.jl"));
cfg = mktemp() do path, io  # write and parse config file on-the-fly
    write(io, generate_sample_config_1())
    flush(io)
    parse_configuration(path)
end
```

The configuration contains the data loader (a closure that only needs to be called with no argument to load the data), the path of the configuration file, the primary id key of the data (which needs to be a [JuliaDB](https://juliadb.org) data type) and a list of configuration objects for the individual searchers of the engine.

```@repl_index
for field in fieldnames(typeof(cfg))
    println("$field=$(getfield(cfg, field))")
end
```

## The search environment
Building the search environment out of the configuration is straightforward. The environment holds the in-memory data in the form of an `IndexedTable` or `NDSparse` object, the searchers as well as other information such as primary db key and configuration paths. 

```@repl_index
env = build_search_env(cfg)
```

## Engine operations
The internal API is designed to be straightforward and uniform in the way it is called. First, one has to build a request which fully describes the operation to be performed and subsequently, call the operation desired. For example, to perform a search, one request would be:
```@repl_index
request = Garamond.InternalRequest(operation=:search,
                                   query="Q",
                                   search_method=:exact,
                                   max_matches=10,
                                   response_size=5,
                                   max_suggestions=0,
                                   return_fields=[:id, :RandString, :StringField],
                                   input_parser=:noop_input_parser,
                                   ranker=:noop_ranker)
```
with searching done by
```@repl_index
search_results = search(env, request)
```
Ranking the results using the ranker specified in the request is done with:
```@repl_index
ranked = rank(env, request, search_results)
```

## Results and responses

Once results are available, these can be printed
```@repl_index
print_search_results(env.dbdata, ranked; id_key=:id, fields=[:id, :RandString])
```
or a JSON response created are sent elsewhere
```@repl_index
response = Garamond.build_response(env.dbdata, request, ranked, id_key=env.id_key)
```
To verify the response, it can be parsed and displayed:
```@repl_index
parsed_response = JSON.parse(response)
parsed_response["results"][collect(keys(parsed_response["results"]))[1]]
```
