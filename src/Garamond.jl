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
    using HNSW, NearestNeighbors, Distances
    using JSON

    # Import section (extendable methods)
    import Base: size, length, show, keys, values, push!,
                 delete!, getindex, names, convert, lowercase,
                 occursin, isempty
    import TextAnalysis: prepare!, id
    import ConceptnetNumberbatch: embed_document

    # Abstract types
    abstract type AbstractId end
    abstract type AbstractSearcher end
    abstract type AbstractSearchData end

    # Exports
    export
        search,
        load_searchers,
        embed_document,
        AbstractId,
        HashId,
        StringId,
        SearchConfig,
        AbstractSearcher,
        Searcher,
        SearchResult,
        id,
        enable!,
        disable!,
        prepare!,
        isenabled,
        print_search_results

    # Include section
    include("defaults.jl")
    include("logging.jl")
    include("config.jl")
    include("embeddings.jl")
    include("search_structures.jl")
    include("search.jl")
    include("results.jl")
    include("utils_text_lang.jl")
    include("parsers/csv_format_1.jl")
    include("cmdline.jl")
    ###include("servers.jl")

end # module
