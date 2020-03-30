abstract type AbstractSearcher{T} end


"""
    Search object. It contains all the indexed data and related
configuration that allows for searches to be performed.
"""
struct Searcher{T<:AbstractFloat,
                E<:AbstractEmbedder{T},
                I<:AbstractIndex} <: AbstractSearcher{T}
    data::Ref
    config::NamedTuple
    input_embedder::Ref{E}                      # embeds queries
    data_embedder::Ref{E}                       # embeds data
    index::I                                    # indexed search data
    search_trees::BKTree{String}                # suggestion structure
end


# Useful methods
id(srcher::Searcher) = srcher.config.id

description(srcher::Searcher) = srcher.config.description

isenabled(srcher::Searcher) = first(srcher.config.enabled)

disable!(srcher::Searcher) = begin
    srcher.config.enabled[1] = false
    nothing
end

enable!(srcher::Searcher) = begin
    srcher.config.enabled[1] = true
    nothing
end


# push!, pushfirst!, pop!, popfirst!, delete!
Base.push!(srcher::Searcher, entry) = pushinner!(srcher, entry, :last)

Base.pushfirst!(srcher::Searcher, entry) = pushinner!(srcher, entry, :first)

pushinner!(srcher::Searcher, entry, position::Symbol) = begin
    document = [dbentry2text(entry, srcher.config.indexable_fields)]
    embedded = first(embed(srcher.data_embedder[], document))
    index_operation = ifelse(position === :first, pushfirst!, push!)
    index_operation(srcher.index, firstcol(embedded))  # push first column i.e. vector
    nothing
end

Base.pop!(srcher::Searcher) = pop!(srcher.index)

Base.popfirst!(srcher::Searcher) = popfirst!(srcher.index)

Base.deleteat!(srcher::Searcher, pos) = delete_from_index!(srcher.index, pos)


# Indexing for vectors of searchers
function getindex(srchers::AbstractVector{Searcher}, an_id::String)
    idxs = Int[]
    for (i, srcher) in enumerate(srchers)
        isequal(id(srcher), an_id) && push!(idxs, i)
    end
    return srchers[idxs]
end


"""
    build_searcher(dbdata, config)

Creates a Searcher from a searcher configuration.
"""
function build_searcher(dbdata, embedders, config; id_key=DEFAULT_DB_ID_KEY)

    # Select embedders
    input_embedder = first(filter(embdr->embdr.config.id==config.input_embedder, embedders))
    data_embedder = first(filter(embdr->embdr.config.id==config.data_embedder, embedders))

    # Create documents
    documents = [dbentry2text(dbentry, config.indexable_fields)
                 for dbentry in db_sorted_row_iterator(dbdata; id_key=id_key, rev=false)]

    # Calculate embeddings for each document
    embedded = first(embed(data_embedder, documents))

    # Build search index
    indexer= build_indexer(config.search_index,
                           config.search_index_arguments,
                           config.search_index_kwarguments)
    srchindex = indexer(embedded)

    # Build search tree (for suggestions)
    srchtree = build_bktree(config.heuristic, documents)

    # Build searcher
    srcher = Searcher(Ref(dbdata),
                      config,
                      Ref(input_embedder),
                      Ref(data_embedder),
                      srchindex,
                      srchtree)

    @debug "* Loaded: $srcher."
    return srcher
end


function build_bktree(heuristic, documents)
    _documents = [join(sentences, " ") for sentences in documents]  # merge sentences
    lexicon = create_lexicon(_documents, 1)
    if heuristic != nothing
        distance = get(HEURISTIC_TO_DISTANCE, heuristic, DEFAULT_DISTANCE)
        fdist = (x,y) -> evaluate(distance, x, y)
        return BKTree(fdist, collect(keys(lexicon)))
    else
        return BKTree{String}()
    end
end


# Supported indexes name to type mapping
function build_indexer(index, args, kwargs)
    default_hnsw_kwarguments = (:efConstruction=>100, :M=>16, :ef=>50)  # to ensure it works well
    default_ivfadc_kwarguments = (:kc=>2, :k=>2, :m=>1)  # to ensure it works at all
    index === :naive && return d->NaiveIndex(d, args...; kwargs...)
    index === :brutetree && return d->BruteTreeIndex(d, args...; kwargs...)
    index === :kdtree && return d->KDTreeIndex(d, args...; kwargs...)
    index === :hnsw && return d->HNSWIndex(d, args...; default_hnsw_kwarguments..., kwargs...)
    index === :ivfadc && return d->IVFIndex(d, args...; default_ivfadc_kwarguments..., kwargs...)
    index === :noop && return d->NoopIndex(d, args...; kwargs...)
end
