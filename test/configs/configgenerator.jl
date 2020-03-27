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
        "data_sampler_name": "identity_sampler",
        "id_key": "id",
        "vectors_eltype": "Float32",
        "embedders": [
            {
                "id": "embedder_1",
                "description": "BM25+RP embedder",
                "embeddable_fields": ["RandString", "StringField", "StringField2", "IntField"],
                "stem_words": false,
                "language": "english",
                "vectors": "bm25",
                "vectors_transform": "rp",
                "vectors_dimension": 50,
                "oov_policy" : "large_vector"
            }
        ],
        "searchers": [
            {
                "id": "searcher_1",
                "id_aggregation": "aggid",
                "description": "A searcher using BM25+RP embeddings and naive indexing",
                "enabled": true,
                "indexable_fields": ["RandString", "StringField", "StringField2", "IntField"],
                "data_embedder": "embedder_1",
                "search_index": "naive",
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
        "data_sampler_name": "identity_sampler",
        "id_key": "id",
        "vectors_eltype": "Float32",
        "embedders": [
            {
                "id": "embedder_1",
                "description": "BM25+RP embedder",
                "embeddable_fields": ["RandString", "StringField", "StringField2", "IntField"],
                "stem_words": false,
                "language": "english",
                "vectors": "bm25",
                "vectors_transform": "rp",
                "vectors_dimension": 50,
                "oov_policy" : "large_vector"
            },
            {
                "id": "embedder_2",
                "description": "Word2Vec BOE embedder",
                "stem_words": false,
                "language": "english",
                "vectors": "word2vec",
                "vectors_transform": "none",
                "embeddings_path": "$(generate_embeddings_path())",
                "embeddings_kind": "binary",
                "doc2vec_method": "boe",
                "embedder_kwarguments": {},
                "oov_policy" : "large_vector"
            }
        ],
        "searchers": [
            {
                "id": "searcher_1",
                "id_aggregation": "aggid",
                "description": "A searcher using BM25+RP embeddings and naive indexing",
                "enabled": true,
                "indexable_fields": ["RandString", "StringField", "StringField2", "IntField"],
                "data_embedder": "embedder_1",
                "search_index": "naive",
                "score_alpha": 0.4,
                "score_weight": 0.8
            },
            {
                "id": "searcher_2",
                "id_aggregation": "aggid",
                "description": "A searcher using Word2Vec embeddings and naive indexing",
                "enabled": true,
                "indexable_fields": ["StringField2"],
                "data_embedder": "embedder_2",
                "search_index": "ivfadc",
                "search_index_arguments": [],
                "search_index_kwarguments": {"kc":4, "m":4},
                "score_alpha": 0.4,
                "score_weight": 0.8
            }
        ]
    }
"""
end
