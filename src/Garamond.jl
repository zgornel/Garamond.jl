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
#
# ~Garamond~ - Search engine written at 0x0α Research by Corneliu Cofaru, 2018, 2019.
#
module Garamond

    # Using section
    using Unicode
    using Random
    using Logging
    using Dates
    using DelimitedFiles
    using Sockets
    using LinearAlgebra
    using SparseArrays
    using Statistics
    using DataStructures
    using Memento
    using Dispatcher
    using DispatcherCache
    using StringAnalysis, Languages
    using StringDistances, BKTrees
    using ArgParse
    using ProgressMeter
    using ConceptnetNumberbatch, Word2Vec, Glowe
    using HNSW, NearestNeighbors, Distances
    using LightGraphs: Graph, pagerank
    using JSON
    using Glob
    using HTTP
    using TSVD

    # Import section (extendable methods)
    import Base: size, length, show, keys, values, push!,
                 delete!, getindex, names, convert, lowercase,
                 occursin, isempty
    import StringAnalysis: id, embed_document
    import Word2Vec: WordVectors

    # Abstract types
    abstract type AbstractSearchModel end

    # Exports
    export
        search,
        load_searchers,
        Searcher,
        SearchConfig,
        SearchResult,
        id, description,
        isenabled, enable!,
        disable!,
        print_search_results

    # Include section
    include("config/defaults.jl")
    include("config/engine.jl")
    include("config/data.jl")
    include("logging.jl")
    include("textutils.jl")
    include("embeddings.jl")
    include("structs.jl")
    include("srchmodels.jl")
    include("update.jl")
    include("search.jl")
    include("results.jl")
    include("requests.jl")
    include("servers.jl")
    include("version.jl")
    include("parsers/delimited_formats.jl")
    include("parsers/directory_formats.jl")
    include("parsers/no_parse.jl")

end # module
