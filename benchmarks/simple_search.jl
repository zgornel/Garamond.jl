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
needles = ["patteryn", "pattern", "clark", "sade", "a"]

MAX_SUGGESTIONS = 0
MAX_CORPUS_SUGGESTIONS = 15

cs2 = cs[_id]
run_search_corpus() = search(cs2, needles, search_type=ST, search_method=SM, max_suggestions=MAX_SUGGESTIONS)[2]
run_search_corpora() = search(cs, needles, search_type=ST, search_method=SM, max_suggestions=MAX_SUGGESTIONS,
                             max_corpus_suggestions=MAX_CORPUS_SUGGESTIONS);

result = run_search_corpora()
print_search_results(cs, result)
println("----")
println("---- Corpora search ----")
disable!(cs, _id_disabled)
@btime run_search_corpora()
println("---- Corpus search ----")
@btime run_search_corpus()
println("---- Direct search ----")
@btime Garamond.search(needles, cs[_id].term_importances[ST], search_method=SM)
