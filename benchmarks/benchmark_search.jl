# Small Garamond benchmark script; has to be run from the Garamond
# root package directory
using Pkg;
Pkg.activate(".");
using DataStructures
using Garamond
using TextAnalysis
using BenchmarkTools
cs = corpora_searchers("./config/.cornel_data")

_id = StringId("biglib")
_id_disabled = StringId("techlib");
ST = :index
SM = :exact
needles = ["patteryn", "pattern", "clark", "sade"]
MAX_SUGGESTIONS=5

cs2 = cs[_id]
run_search_corpus() = search(cs2, needles, search_type=ST, search_method=SM, max_suggestions=MAX_SUGGESTIONS)
run_search_corpora() = search(cs, needles, search_type=ST, search_method=SM, max_suggestions=MAX_SUGGESTIONS);

print_search_results(cs, run_search_corpora())
println("----")

println("---- Corpora search ----")
disable!(cs, _id_disabled)
@btime run_search_corpora()
println("---- Corpus search ----")
@btime run_search_corpus()
println("---- Direct search ----")
@btime Garamond.search(needles, cs[_id].term_importances[ST], search_method=SM)
