# Embedders
show(io::IO, embdr::E) where {E<:AbstractEmbedder} = begin
    local _vecs, _embedder, _indim, _outdim
    if E <: WordVectorsEmbedder
        _indim = size(embdr.embeddings)[1]
        _outdim = dimensionality(embdr)
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
        L = typeof(embdr.embeddings)
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
        _vecs = "DTV($(embdr.config.vectors))"
        _indim = length(embdr.model.vocab)
        _outdim = _indim
        L = typeof(embdr.model)
        if L <: StringAnalysis.LSAModel
            _embedder = "LSA"
            _outdim = dimensionality(embdr)
        elseif L <: StringAnalysis.RPModel && embdr.config.vectors_transform==:rp
            _embedder = "RP"
            _outdim = dimensionality(embdr)
        else
            _embedder = "-"
        end
    end
    printstyled(io, "$_embedder embedder, $_indim to $_outdim, $_vecs vectors")
end


# Searcher
show(io::IO, srcher::Searcher{T,E,I}) where {T,E,I} = begin
    _status = ifelse(isenabled(srcher), "enabled", "disabled")
    _status_color = ifelse(isenabled(srcher), :light_green, :light_black)
    printstyled(io, "[$_status] ", color=_status_color, bold=true)
    printstyled(io, "Searcher $(id(srcher))/")
    printstyled(io, "$(srcher.config.id_aggregation)", bold=true)
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
    printstyled(io, ", $(length(srcher.index)) $T embedded documents, ")
    # Get embeddings type string
    _embsstr = ifelse(srcher.data_embedder[] === srcher.input_embedder[],
                      "one embedder", "two embedders")
    printstyled(io, "$_embsstr")
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
    printstyled(io, "  sampler = ")
    printstyled(io, "$(repr(env.sampler))\n", bold=true)
    printstyled(io, "  embedders = [\n")
    printstyled(io, "$(join(map(o->"    "*repr(o), env.embedders), "\n"))\n", bold=true)
    printstyled(io, "  ]\n")
    printstyled(io, "  searchers = [\n")
    printstyled(io, "$(join(map(o->"    "*repr(o), env.searchers), "\n"))\n", bold=true)
    printstyled(io, "  ]\n")
    printstyled(io, "  config_path = ")
    printstyled(io, "$(env.config_path)", bold=true)
end
