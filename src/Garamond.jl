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
    using Statistics
    using SparseArrays
    using QuantizedArrays
    using DataStructures
    using Memento
    using Dispatcher
    using DispatcherCache
    using Languages
    using StringAnalysis
    using StringDistances
    using BKTrees
    using ArgParse
    using ProgressMeter
    using ConceptnetNumberbatch
    using Word2Vec
    using Glowe
    using EmbeddingsAnalysis
    using HNSW
    using NearestNeighbors
    using Distances
    using LightGraphs: Graph, pagerank
    using JSON
    using Glob
    using HTTP
    using TSVD

    # Import section (extendable methods)
    import Base: size, length, show, keys, values, push!,
                 delete!, getindex, names, convert, lowercase,
                 occursin, isempty, parse
    import StringAnalysis: id
    import Word2Vec: WordVectors

    # Exports
    export
        search,
        load_searchers,
        AbstractEmbedder,
        AbstractIndex,
        Searcher,
        SearchConfig,
        SearchResult,
        id, description,
        isenabled, enable!, disable!,
        print_search_results,
        search_server,
        unix_socket_server,
        web_socket_server,
        rest_server

    # Include section
    include("config/defaults.jl")
    include("config/engine.jl")
    include("config/search.jl")
    include("logging.jl")
    include("textutils.jl")
    include("embedder/abstractembedder.jl")
    include("embedder/wordvectors.jl")
    include("embedder/boe.jl")
    include("embedder/sif.jl")
    include("embedder/borep.jl")
    include("embedder/cpmean.jl")
    include("embedder/disc.jl")
    include("embedder/dtv.jl")
    include("index/abstractindex.jl")
    include("index/naive.jl")
    include("index/brutetree.jl")
    include("index/kdtree.jl")
    include("index/hnsw.jl")
    include("structs.jl")
    include("update.jl")
    include("search.jl")
    include("results.jl")
    include("version.jl")
    include("server/requests.jl")
    include("server/unixsocket.jl")
    include("server/websocket.jl")
    include("server/rest.jl")
    include("server/search_server.jl")
    include("parsers/delimited_formats.jl")
    include("parsers/directory_formats.jl")
    include("parsers/no_parse.jl")
    include("parsers/json.jl")
    include("show.jl")

end # module
