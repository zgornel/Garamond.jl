function juliadb_loader(data; ingest=false, kwargs...)
    loadtable(data; kwargs...)  # Returnes either a NDSparse or IndexedTable
end
