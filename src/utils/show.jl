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
    printstyled(io, "$(sconfig.vectors)$_tf\n", bold=true)
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
        _index_type = "Naive index"
    elseif I <: BruteTreeIndex
        _index_type = "BruteTree index"
    elseif I<: KDTreeIndex
        _index_type = "KDTree index"
    elseif I <: HNSWIndex
        _index_type = "HNSW index"
    elseif I <: IVFIndex
        _index_type = "IVFADC index"
    elseif I <: NoopIndex
        _index_type = "Noop index"
    else
        _index_type = "<Unknown index>"
    end
    printstyled(io, "$_index_type", bold=true)
    #printstyled(io, "$(description(srcher))", color=:normal)
    printstyled(io, ", $(length(srcher.index)) $T embedded documents")
end


# SearchResult
show(io::IO, result::SearchResult) = begin
    n = length(result.query_matches)
    nm = length(result.needle_matches)
    ns = length(result.suggestions)
    printstyled(io, "Search results for $(result.id): ")
    printstyled(io, " $n hits, $nm query terms, $ns suggestions.", bold=true)
end


# InternalRequest
show(io::IO, request::T) where {T<:InternalRequest} = begin
    _field_lengths = Dict(:query => 50)
    itstr = (uppercase(string(field)) * "=" *
               chop_to_length(repr(getproperty(request, field)),
                              get(_field_lengths, field, 10))
             for field in fieldnames(T))
    print(io, "InternalRequest: ", join(itstr, " | "))
end


# SearchEnv
Base.show(io::IO, env::SearchEnv{T}) where {T} = begin
    print(io, "SearchEnv{$T} with:\n")
    printstyled(io, "`-dbdata = ")
    buf = IOBuffer();
    print(buf, env.dbdata);
    seekstart(buf);
    dbstr = readuntil(buf, ':')
    printstyled(io, "$(dbstr)\n", bold=true)
    printstyled(io, "  id_key = ")
    printstyled(io, "$(env.id_key)\n", bold=true)
    printstyled(io, "  searchers = ")
    printstyled(io, "$(length(env.searchers))\n", bold=true)
    printstyled(io, "  config_path = ")
    printstyled(io, "$(env.config_path)", bold=true)
end
