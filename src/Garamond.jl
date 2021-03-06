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

    using Unicode
    using Random
    using Logging
    using Dates
    using DelimitedFiles
    using Sockets
    using LinearAlgebra
    using Statistics
    using Serialization
    using PooledArrays
    using SparseArrays
    using QuantizedArrays
    using DataStructures
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
    using IVFADC
    using Distances
    using LightGraphs: Graph, pagerank
    using JSON
    using HTTP
    using TSVD
    using JuliaDB

    import Base: size, length, show, keys, values,
                 delete!, getindex, names, convert, lowercase,
                 occursin, isempty, parse, sort
    import StringAnalysis: id
    import Word2Vec: WordVectors
    import HNSW: knn_search

    export
        search,
        recommend,
        rank,
        indexfilter,

        build_search_env,
        parse_configuration,
        parse_input,

        AbstractEmbedder,
        embed,
        embed!,

        AbstractIndex,
        NaiveIndex,
        BruteTreeIndex,
        KDTreeIndex,
        HNSWIndex,
        IVFIndex,
        NoopIndex,

        SearchEnv,
        AbstractSearcher,
        Searcher,
        SearchResult,

        id,
        description,
        isenabled, enable!, disable!,
        print_search_results,
        search_server,
        unix_socket_server,
        web_socket_server,
        rest_server

    #=
    The __init__() function includes at runtime all the .jl files located
    at data/loaders/custom; the files should be either code or symlinks to
    files containing data loading functions that take data paths as input
    argument and return IdexedTable/NDSparse datasets representing the data
    to be indexed.
    =#
    function __init__()
        CUSTOM_LOADERS_SUBDIR = "data/loaders/custom"
        CUSTOM_SAMPLERS_SUBDIR = "data/samplers/custom"
        CUSTOM_RANKERS_SUBDIR = "search/rankers/custom"
        CUSTOM_RECOMMENDERS_SUBDIR = "search/recommenders/custom"
        CUSTOM_INPUT_SUBDIR = "input/custom"

        __include_subdirectory(CUSTOM_LOADERS_SUBDIR, printer="Loaders (custom)")
        __include_subdirectory(CUSTOM_SAMPLERS_SUBDIR, printer="Samplers (custom)")
        __include_subdirectory(CUSTOM_RANKERS_SUBDIR, printer="Rankers (custom)")
        __include_subdirectory(CUSTOM_RECOMMENDERS_SUBDIR, printer="Recommenders (custom)")
        __include_subdirectory(CUSTOM_INPUT_SUBDIR, printer="Parsers (custom)")
    end

    function __include_subdirectory(subpath; printer="Including")
        fullpath = joinpath(@__DIR__, subpath)
        if isdir(fullpath)
            included_files = String[]
            for file in readdir(fullpath)
                local filepath
                try
                    filepath = joinpath(fullpath, file)
                    if isfile(filepath) && endswith(filepath, ".jl")
                        include(filepath)
                        push!(included_files, file)
                    end
                catch e
                    @warn "Could not include \"$filepath\".\n$e"
                end
            end

            !isempty(included_files) &&
                @info "• " * printer * ": " * join(included_files, ", ")
        end
    end

    include("data/db.jl")
    include("data/text.jl")
    include("data/parse_and_eval.jl")
    include("data/loaders/noop.jl")
    include("data/loaders/juliadb.jl")

    include("data/samplers/noop.jl")
    include("data/samplers/identity.jl")

    include("config/defaults.jl")
    include("config/engine.jl")

    include("embedder/interface.jl")
    include("embedder/wordvectors.jl")
    include("embedder/boe.jl")
    include("embedder/sif.jl")
    include("embedder/borep.jl")
    include("embedder/cpmean.jl")
    include("embedder/disc.jl")
    include("embedder/dtv.jl")

    include("index/interface.jl")
    include("index/naive.jl")
    include("index/brutetree.jl")
    include("index/kdtree.jl")
    include("index/hnsw.jl")
    include("index/ivfadc.jl")
    include("index/noop.jl")

    include("searchable/config_parser.jl")
    include("searchable/searcher.jl")
    include("searchable/env.jl")
    include("searchable/env_operations.jl")

    include("input/text_parsers.jl")

    include("search/index.jl")
    include("search/filter.jl")
    include("search/results.jl")
    include("search/recommend.jl")
    include("search/recommenders/search.jl")
    include("search/recommenders/noop.jl")
    include("search/rank.jl")
    include("search/rankers/noop.jl")
    include("search/main.jl")

    include("server/requests.jl")
    include("server/unixsocket.jl")
    include("server/websocket.jl")
    include("server/rest.jl")
    include("server/search.jl")

    include("utils/logging.jl")
    include("utils/show.jl")
    include("utils/version.jl")

end # module
