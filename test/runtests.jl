using Test
using Random
using Garamond

@test true # Do not test anything yet

@testset "Basic test..." begin

    corpora_searcher = corpora_searchers("./data/.test_data_config")
    _id = StringId("specific_id")
    _id_disabled = "disabled_id"
    ST = [:index, :metadata, :all]
    SM = [:exact, :regex]
    needles = [randstring(rand([1,2,3])) for _ in 1:5]
    MAX_SUGGESTIONS=[0, 5]
    enable!(corpora_searcher, _id_disabled)
    corpus_searcher = corpora_searcher[_id]
    # Test that the whole thing does not crash
    for search_type in ST
        for search_method in SM
            for max_suggestions in MAX_SUGGESTIONS
                try
                    search(corpora_searcher,
                           needles,
                           search_type=search_type,
                           search_method=search_method,
                           max_suggestions=max_suggestions)
                    @test true
                catch
                    @test false
                end
            end
        end
    end
end
