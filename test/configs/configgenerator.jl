function generate_data_path()
    root_path = "/" * joinpath(split(pathof(Garamond), "/")[1:end-2]...)
    data_path = joinpath(root_path, "test", "data", "generated_data_100_samples.csv")
end


function generate_embeddings_path()
    root_path = "/" * joinpath(split(pathof(Garamond), "/")[1:end-2]...)
    embeddings_path = joinpath(root_path, "test", "embeddings", "word2vec", "sample_model.bin")
end


function generate_sample_config_1()
    text = """
	{
        "data_loader_name": "juliadb_loader",
        "data_loader_arguments": ["$(generate_data_path())"],
        "id_key": "id",
        "searchers": [
            {
                "id": "searcher_1",
                "id_aggregation": "aggid",
                "description": "A searcher using BM25+RP embeddings and naive indexing",
                "enabled": true,
                "indexable_fields": ["RandString", "StringField", "StringField2", "IntField"],
                "stem_words": false,
                "language": "english",
                "vectors": "bm25",
                "vectors_transform": "rp",
                "vectors_dimension": 50,
                "vectors_eltype": "Float32",
                "search_index": "naive",
                "oov_policy" : "large_vector",
                "score_alpha": 0.4,
                "score_weight": 0.8
            }
        ]
    }
    """
end

function generate_sample_config_2()
    text = """
    {
        "data_loader_name": "juliadb_loader",
        "data_loader_arguments": ["$(generate_data_path())"],
        "id_key": "id",
        "searchers": [
            {
                "id": "searcher_1",
                "id_aggregation": "aggid",
                "description": "A searcher using BM25+RP embeddings and naive indexing",
                "enabled": true,
                "indexable_fields": ["RandString", "StringField", "StringField2", "IntField"],
                "stem_words": false,
                "language": "english",
                "vectors": "bm25",
                "vectors_transform": "rp",
                "vectors_dimension": 50,
                "vectors_eltype": "Float32",
                "search_index": "naive",
                "oov_policy" : "large_vector",
                "score_alpha": 0.4,
                "score_weight": 0.8
            },
            {
                "id": "searcher_2",
                "id_aggregation": "aggid",
                "description": "A searcher using Word2Vec embeddings and naive indexing",
                "enabled": true,
                "indexable_fields": ["StringField2"],
                "stem_words": false,
                "language": "english",
                "vectors": "word2vec",
                "vectors_transform": "none",
                "vectors_eltype": "Float32",
                "search_index": "naive",
                "embeddings_path": "$(generate_embeddings_path())",
                "embeddings_kind": "binary",
                "doc2vec_method": "boe",
                "oov_policy" : "large_vector",
                "score_alpha": 0.4,
                "score_weight": 0.8
            }
        ]
    }
"""
end
