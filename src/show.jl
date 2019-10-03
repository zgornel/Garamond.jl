# StringID
show(io::IO, id::StringId) = print(io, "id=\"$(id.value)\"")


# SearchConfig
Base.show(io::IO, sconfig::SearchConfig) = begin
    printstyled(io, "SearchConfig for $(sconfig.id) "*
                "(aggregation $(sconfig.id_aggregation))\n")
    printstyled(io, "`-enabled = ")
    printstyled(io, "$(sconfig.enabled)\n", bold=true)
    _tf = ""
    if sconfig.vectors in [:count, :tf, :tfidf, :b25]
        if sconfig.vectors_transform == :lsa
            _tf = " + LSA"
        elseif sconfig.vectors_transform == :rp
            _tf = " + random projection"
        end
    end
    printstyled(io, "  vectors = ")
    printstyled(io, "$(sconfig.vectors)$_tf", bold=true)
    printstyled(io, ", ")
    printstyled(io, "$(sconfig.vectors_eltype)\n", bold=true)
    printstyled(io, "  search_index = ")
    printstyled(io, "$(sconfig.search_index)\n", bold=true)
    if sconfig.embeddings_path != nothing
        printstyled(io, "  embeddings_path = ")
        printstyled(io, "\"$(sconfig.embeddings_path)\"\n", bold=true)
    end
end


# Searcher
show(io::IO, srcher::Searcher{T,E,I}) where {T,E,I} = begin
    _status = ifelse(isenabled(srcher), "enabled", "disabled")
    _status_color = ifelse(isenabled(srcher), :light_green, :light_black)
    printstyled(io, "[$_status] ", color=_status_color, bold=true)
    printstyled(io, "Searcher $(id(srcher))/")
    printstyled(io, "$(srcher.config.id_aggregation)", bold=true)
    printstyled(io, ", ")

    # Get embeddings type string
    local _vecs, _embedder, _indim, _outdim
    if E <: WordVectorsEmbedder
        _indim = size(srcher.embedder.embeddings)[1]
        _outdim = dimensionality(srcher.embedder)
        if E<:BOEEmbedder
            _embedder = "BOE"
        elseif E<:SIFEmbedder
            _embedder = "SIF"
        elseif E<:BOREPEmbedder
            _embedder = "BOREP"
        elseif E<:CPMeanEmbedder
            _embedder = "CPMean"
        elseif E<:DisCEmbedder
            _embedder = "DisC"
        else
            _embedder = "?"
        end
        L = typeof(srcher.embedder.embeddings)
        if L <: Word2Vec.WordVectors
            _vecs = "Word2Vec"
        elseif L <: Glowe.WordVectors
            _vecs = "GloVe"
        elseif L <: ConceptnetNumberbatch.ConceptNet
            _vecs = "Conceptnet"
        elseif L <: EmbeddingsAnalysis.CompressedWordVectors
            _vecs = "Compressed"
        else
            _vecs = "?"
        end
    elseif E<: DTVEmbedder
        _vecs = "DTV($(srcher.config.vectors))"
        _indim = length(srcher.embedder.model.vocab)
        _outdim = _indim
        L = typeof(srcher.embedder.model)
        if L <: StringAnalysis.LSAModel
            _embedder = "LSA"
            _outdim = dimensionality(srcher.embedder)
        elseif L <: StringAnalysis.RPModel && srcher.config.vectors_transform==:rp
            _embedder = "RP"
            _outdim = dimensionality(srcher.embedder)
        else
            _embedder = "-"
        end
    end
    printstyled(io, "$_vecs($_indim)/$_embedder($_outdim)", bold=true)
    printstyled(io, ", ")

    # Get search index type string
    if I <: NaiveIndex
        _index_type = "Naive/Matrix"
    elseif I <: BruteTreeIndex
        _index_type = "Brute-Tree"
    elseif I<: KDTreeIndex
        _index_type = "KD-Tree"
    elseif I <: HNSWIndex
        _index_type = "HNSW"
    else
        _index_type = "<Unknown>"
    end
    printstyled(io, "$_index_type", bold=true)
    #printstyled(io, "$(description(srcher))", color=:normal)
    printstyled(io, ", $(length(srcher.index)) $T embedded documents")
end


# SearchResult
show(io::IO, result::SearchResult) = begin
    n = valength(result.query_matches)
    nm = length(result.needle_matches)
    ns = length(result.suggestions)
    printstyled(io, "Search results for $(result.id): ")
    printstyled(io, " $n hits, $nm query terms, $ns suggestions.", bold=true)
end


# SearchServerRequest
show(io::IO, request::T) where {T<:SearchServerRequest} = begin
    print(io, "Request: ")
    for field in fieldnames(T)
        print(io, field, "=", getproperty(request, field), " | ")
    end
end


# SearchEnv
Base.show(io::IO, env::SearchEnv) = begin
    print(io, "SearchEnv, ", length(env.searchers), " searchers, ",
          length(env.dbdata), " samples")
end
