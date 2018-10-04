module Garamond

    using Distributed
    using Unicode
    using TextAnalysis, Languages
    using ConceptnetNumberbatch
    ###using LightGraphs, NearestNeighbors, MLKernels
    ###using HttpServer, WebSockets, JSON
    #using JSON
    ###using ArgParse
    using SparseArrays: spzeros
    using Statistics: mean  # can be removed if fuzzy matcher is removed
    using DataStructures: Set, MultiDict

    import Base: show, keys, values, push!, delete!, getindex,
           names, convert, lowercase, occursin
    import TextAnalysis: prepare!, update_lexicon!,
           update_inverse_index!

    export
        # Corpora related
        AbstractCorpora,
        CorpusRef,
        Corpora,
        update_lexicon!,
        update_inverse_index!,
        enable!,
        disable!,
        load_corpora,
        add_corpus!,
        # Utils
        prepare!,
        # Search related
        contains,
        fuzzysort,
        levsort,
        search,
        search_metadata,
        search_index,
        search_heuristically
        #HTTP server
        ###start_http_server,
        # Command line (application) related
        ###get_commandline_arguments,
        # Word embeddings
        ###find_cluster_mean,
        ###get_cluster_matrix,
        ###get_cluster_matrix!,
        ###find_close_clusters,
        ###path

    include("parsers.jl")
    include("corpus.jl")
    include("utils_text_lang.jl")
    include("search.jl")
    ###include("cmdline.jl")
    ###include("servers.jl")
    ###include("word_model_utils.jl")

end # module
