module Garamond

    using Random
    using Unicode
    using DelimitedFiles
    using SparseArrays
    using Distributed
    using Base.Threads
    using Statistics: mean
    using DataStructures: Set, MultiDict
    using TextAnalysis, Languages
    using ConceptnetNumberbatch
    using StringDistances, BKTrees
    using ArgParse
    using ProgressMeter
    ###using LightGraphs, NearestNeighbors, MLKernels
    ###using HttpServer, WebSockets, JSON
    #using JSON

    import Base: show, keys, values, push!, delete!, getindex,
           names, convert, lowercase, occursin, isempty
    import TextAnalysis: prepare!, update_lexicon!,
           update_inverse_index!

    abstract type AbstractId end
    abstract type AbstractSearcher end

    export
        # Corpora related
        AbstractId,
        HashId,
        StringId,
        CorpusRef,
        AbstractSearcher,
        CorpusSearcher,
        CorporaSearcher,
        corpora_searchers,
        add_searcher!,
        enable!,
        disable!,
        # Utils
        prepare!,
        # Search related
        search,
        search_heuristically,
        print_search_results,
        # Command line (application) related
        get_commandline_arguments
        #HTTP server
        ###start_http_server,
        # Word embeddings
        ###find_cluster_mean,
        ###get_cluster_matrix,
        ###get_cluster_matrix!,
        ###find_close_clusters,
        ###path

    # Include section
    include("defaults.jl")
    include("corpora_searchers.jl")
    include("parsers.jl")
    include("utils_text_lang.jl")
    include("results.jl")
    include("search.jl")
    include("cmdline.jl")
    ###include("servers.jl")
    ###include("word_model_utils.jl")

end # module
