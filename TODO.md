# Short term
- High priority
    - Take testing seriously
    - Take metadata search seriously (i.e. decide on facets, what fields to use/index etc)
    - Take scoring seriously (build scoring function i.e. normalize document scores, map non-linearly to arbitrary scale; add influence of key-term hit-rate i.e. terms in query found)
- Low priority
    - Improve re-indexing mechanism (i.e. @spawn worker, use incremental approach)
    - Improve speed for suggestions, re-visit mechanism
    - Implement mechanism for query expansion
    - Define (decide on) mechanisms to combine semantic and classic searches (i.e. classic for filtering, semantic for ordering)

# Long term
- Data gathering: web crawler (either implement or support), data streaming sink APIs (should be in distinct support packages)
- Reliable search from any language to any language (external APIs?, dictionaries ?)
- Abstract semantic search (search into 1-D, 2-D signals i.e. sound, images)
- Ontology builder and explorer; (see [Conceptnet](https://github.com/commonsense/conceptnet5)); arbitrary query to target ontology linking
- P2P
- [Flux.jl](https://github.com/FluxML/Flux.jl) native embedding generation (i.e. custom embedding generation model architectures)



