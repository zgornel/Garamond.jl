# Small Garamond benchmark script; has to be run from the Garamond
# root package directory
using Pkg;
Pkg.activate(".");
using DataStructures
using Garamond
using TextAnalysis
using BenchmarkTools
corpora = load_corpora("./config/.cornel_data")

_id = HashId(0xe3c8b83a015f6004);
_id_disabled =HashId(0x3ac6551533cb171d);
ST = :metadata
SM = :exact
needles = ["patteryn", "pattern", "clark", "sade"]
MAX_SUGGESTIONS=0
#@btime rr=search(corpora[id], needles, search_type=ST, search_method=:exact, max_suggestions=2, search_tree=corpora.search_trees[id, ST])
crps = corpora.corpus[_id]
run_search_corpus() = search(crps, needles, search_type=ST, search_method=SM, max_suggestions=MAX_SUGGESTIONS,
                             search_trees=corpora.search_trees[_id], index=corpora.index[_id]);
run_search_corpora() = search(corpora, needles, search_type=ST, search_method=SM, max_suggestions=MAX_SUGGESTIONS);

print_search_results(corpora, run_search_corpora())
println("----")

println("---- Corpora search ----")
disable!(corpora, _id_disabled)
@btime run_search_corpora()
println("---- Corpus search ----")
@btime run_search_corpus()
println("---- Index search ----")
n_docs = length(corpora.corpus[_id])
@btime Garamond.search_index(corpora[_id][ST], needles, n_docs=n_docs, search_method=SM)
