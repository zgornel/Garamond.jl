# Simple usage example

## Classic search
The following code snippet runs a quick and dirty search:
```julia
# Use packages
using Pkg;
Pkg.activate(".");
using Garamond

# Load searchers
filepath = ["/home/zgornel/projects/extras_for_Garamond/data/Cornel/delimited/config_cornel_data_classic.json"]
srchers = load_searchers(filepath);

# Search
QUERY = "arthur clarke pattern"
results = search(srchers, QUERY)
```
The search results promptly appear:
```julia
# 2-element Array{SearchResult,1}:
#  Search results for id="biglib-classic":  7 hits, 2 query terms, 0 suggestions.
#  Search results for id="techlib-classic":  2 hits, 1 query terms, 0 suggestions.
```
To view them in a more detailed fashion i.e. including metadata, one can run:
```julia
print_search_results(srchers, results)
```
which prints:
```julia
# 9 search results from 2 corpora
# `-[id="biglib-classic"] 7 search results:
#   2.9344456 ~ 1-["The last theorem" by Arthur C. Clarke, 2008 (2010)]
#   2.5842855 ~ 2-["2010: odyssey two" by Arthur C. Clarke, 1982 (2010)]
#   2.059056 ~ 4-["Childhood's end" by Arthur C. Clarke, 1954 (2013)]
#   2.059056 ~ 6-["3001: the final odyssey" by Arthur C. Clarke, 1968 (1997)]
#   2.059056 ~ 7-["2061: odyssey three" by Arthur C. Clarke, 1987 (1988)]
#   1.8586512 ~ 3-["The city and the stars" by Arthur C. Clarke, 1956 (2003)]
#   1.8586512 ~ 5-["2001: a space odyssey" by Arthur C. Clarke, 1968 (2001)]
# `-[id="techlib-classic"] 2 search results:
#   0.6101619 ~ 3-["Pattern recognition 4'th edition" by Sergios Theodoridis, Konstantinos Koutroumbas, 2008 (2008)]
#   0.37574464 ~ 2-["Pattern classification, 2'nd edition" by Richard O. Douda, Peter E. Hart, David G. Stork, 2000 (2000)]
```

## Semantic search
Performing a semantic search is very similar to performing a classic one, the difference being that another data configuration file must be provided:
```julia
# Load searchers
filepath = ["/home/zgornel/projects/extras_for_Garamond/data/Cornel/delimited/config_cornel_data_semantic.json"]
srchers = load_searchers(filepath);

# Search
QUERY = "space fiction and planets galore"
results = search(srchers, QUERY, max_matches=10)
```
which yields:
```julia
# 2-element Array{SearchResult,1}:
#  Search results for id="biglib-semantic":  10 hits, 0 query terms, 0 suggestions.
#  Search results for id="techlib-semantic":  5 hits, 0 query terms, 0 suggestions.
```
In this case,
```julia
print_search_results(srchers, results)
```
prints:
```julia
# 15 search results from 2 corpora
# `-[id="biglib-semantic"] 10 search results:
#   1.4016596138408786 ~ 5-["2001: a space odyssey" by Arthur C. Clarke, 1968 (2001)]
#   1.3030687835002375 ~ 3-["The city and the stars" by Arthur C. Clarke, 1956 (2003)]
#   1.1831628403122616 ~ 2-["2010: odyssey two" by Arthur C. Clarke, 1982 (2010)]
#   1.1558528687320448 ~ 65-["Of love and other demons" by Gabriel Garcia Marquez, 1994 (2012)]
#   1.1384422864227708 ~ 10-["A legend of the future" by Augustin De Rojas, 1985 (2014)]
#   1.0947549384771254 ~ 62-["Love in the time of cholera" by Gabriel Garcia Marquez, 1985 (2012)]
#   1.0729641968647925 ~ 31-["The devil and the good lord" by Jean-Paul Sartre, 1951 (2007)]
#   1.0320209929919373 ~ 1-["The last theorem" by Arthur C. Clarke, 2008 (2010)]
#   1.0250176565568312 ~ 21-["In the miso soup" by Ryu Murakami, 1997 (2006)]
#   1.0 ~ 47-["Jailbird" by Kurt Vonnegut, 1979 (2009)]
# `-[id="techlib-semantic"] 5 search results:
#   1.1470548192935575 ~ 1-["Data classification: algorithms and applications" by Charu C. Aggarwal, 2014 (2014)]
#   0.9473624595100231 ~ 5-["Numerical methods for engineers" by Steven C. Chapra, Raymond P. Canale, 2014 (2014)]
#   0.8689249981976931 ~ 3-["Pattern recognition 4'th edition" by Sergios Theodoridis, Konstantinos Koutroumbas, 2008 (2008)]
#   0.8644211963883863 ~ 4-["Artificial intelligence, a modern approach 3'rd edition" by Stuart Russel, Peter Norvig, 2009 (2016)]
#   0.7924568154973227 ~ 2-["Pattern classification, 2'nd edition" by Richard O. Douda, Peter E. Hart, David G. Stork, 2000 (2000)]
```
