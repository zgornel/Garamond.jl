# Small Garamond benchmark script; has to be run from the Garamond
# root package directory
using Pkg;
Pkg.activate(".");
using DataStructures
using Garamond
using TextAnalysis
using BenchmarkTools
corpora = load_corpora("./config/.cornel_data")

id=0xf9bfce7328a18522; 
ST = :index
SM = :regex
needles = ["patternz", "pattern", "clark", "sade"]
MAX_SUGGESTIONS=3
#@btime rr=search(corpora[id], needles, search_type=ST, search_method=:exact, max_suggestions=2, search_tree=corpora.search_trees[id, ST])
rr2 = search(corpora, needles, search_type=ST, search_method=SM, max_suggestions=MAX_SUGGESTIONS);
print(rr2)
@btime search(corpora, needles, search_type=ST, search_method=SM, max_suggestions=MAX_SUGGESTIONS)
