##################################################################################################################
#MMMMMMMMMMMMM0;,MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMo;  oM#
#MM0o:;,',:c;. :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM' oM#
#k.    .lxx:  'WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM' oM#
#    ,KMMMMX   oMMMWlcoolcxWMM0dcoWOo;xMMxclol:dNMMXxlcOkl;,;dXOo:,,cKMMMMM0ocooclkWMMXxlc0kl;,;dWMMMMNxccloo. oM#
#   ;MMMMMK.   :MMMN,WMMM; :MMM0  xk0loMM:0MMMk .MMMM. lKXN0' .0XNXo  NMMW, oWMMMk .KMMM. oXNWK. :MMMx .KMMMM' oM#
#.  ;NWXk;     0MMMMMMWNNl 'MMM0  MMMMMMMMMWNN0  MMMM. kMMMMd .MMMMW  0MMl .MMMMMMc ,MMM. kMMMMo 'MMX  OMMMMM' oM#
#X:          ;KMMMWc.:oxx; 'MMM0  MMMMMMx',oxxo  MMMM. kMMMMd .MMMMW  0MM; 'MMMMMMo .MMM. kMMMMo 'MMO  XMMMMM' oM#
#MO.'OkxxkOXMMMMMMo ,MMMMo 'MMM0  MMMMMK  NMMMX  MMMM. kMMMMd .MMMMW  0MMd .MMMMMM; :MMM. kMMMMo 'MMX  kMMMMM' oM#
#'  kXNNNNNNNWMMMMk  xK0k; 'MMMO  WMMMMN. l00Oo  WMMM. xMMMMo .MMMMN  0MMMl ;KWMXl ,NMMM. kMMMMo 'MMMk  o0XKO. lM#
#;             'dWMKdloxKNxxkW0xxxxOWMMMNxoodOWkxkXXkxxxOWNkxxxkKM0xxxx0MMMWOdoodkXMMMNkxxxOMWOxxxkNMMWOdloxK0xxO#
#Nl.lxxxxxxxdl.  ;MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#
#  KMMMMMMMMMMO  .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#
# .WMMMMMMMMMN,  kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#
#. .lxkOOkxl' .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#
#MXl'.    .,oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#
##################################################################################################################
module Garamond

    # Using section
    using Logging
    using Random
    using Unicode
    using DelimitedFiles
    using LinearAlgebra
    using SparseArrays
    using Base.Threads
    using Statistics: mean
    using DataStructures: Set, MultiDict
    using TextAnalysis, Languages
    using StringDistances, BKTrees
    using ArgParse
    using ProgressMeter
    using ConceptnetNumberbatch, Word2Vec
    using NearestNeighbors, Distances

    # Import section (extendable methods)
    import Base: size, length, show, keys, values, push!,
                 delete!, getindex, names, convert, lowercase,
                 occursin, isempty
    import TextAnalysis: prepare!, update_lexicon!,
           update_inverse_index!
    import ConceptnetNumberbatch: embed_document
    import NearestNeighbors: knn

    # Abstract types
    abstract type AbstractId end
    abstract type AbstractSearcher end
    abstract type AbstractEmbeddingModel end

    # Exports
    export
        # Utils
        prepare!,
        get_document_embedding,
        # Ids
        AbstractId,
        HashId,
        StringId,
        # Search config structure
        SearchConfig,
        # Searchers
        AbstractSearcher,
        ClassicSearcher,
        SemanticSearcher,
        AggregateSearcher,
        classic_searcher,
        semantic_searcher,
        aggregate_searcher,
        enable!,
        disable!,
        # Results
        SearchResult,
        AggregateSearchResult,
        # Search related
        search,
        search_heuristically,
        print_search_results,
        # Command line (application) related
        get_commandline_arguments
        #HTTP server
        ###start_http_server,

    # Include section
    include("defaults.jl")
    include("cmdline.jl")
    include("logging.jl")
    include("utils_text_lang.jl")
    include("embeddings.jl")
    include("search_structures.jl")
    include("parsers.jl")
    include("search.jl")
    include("results.jl")
    ###include("servers.jl")

end # module
