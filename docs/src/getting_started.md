# Getting started

```@repl_index
using Logging
#global_logger(ConsoleLogger(stdout, Logging.Debug))
using Garamond
using JuliaDB
using JSON

path = joinpath(@__DIR__, "..", "..", "test", "configs", "sample_config_1.json")
cfg = parse_configuration(path)

env = build_search_env(cfg)

request = Garamond.InternalRequest(operation=:search,
                                   query="Q",
                                   search_method=:exact,
                                   max_matches=1000,
                                   response_size=5,
                                   max_suggestions=0,
                                   return_fields=[:id, :RandString, :StringField],
                                   input_parser=:noop_input_parser,
                                   ranker=:noop_ranker)

search_results = search(env, request)
ranked = rank(env, request, search_results)
#print_search_results(env.dbdata, ranked, fields=[:id, :RandString])

response = Garamond.build_response(env.dbdata, request, ranked, id_key=env.id_key)
parsed_response = JSON.parse(response)
parsed_response["results"][collect(keys(parsed_response["results"]))[1]]
```
