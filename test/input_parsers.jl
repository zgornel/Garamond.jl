using Test
using Random
using JuliaDB
using Garamond

tbl = table((y = rand(10),
             x = collect(1:10),
             z = [randstring(1) for _ in 1:10]);
            pkey=:x)

env = Garamond.SearchEnv(tbl, :x, nothing, nothing)

QUERIES = [(input_query = "this is a query", filter_response = Dict{String,Any}(), search_response = "this is a query"),
           (input_query = "search token x:10 y:1 z:\"a\"", filter_response = Dict(:x=>10, :y=>1.0, :z=>"a"), search_response = "search token"),
           (input_query = "x:[1,2,3] y:(\"a\",) z:", filter_response = Dict(:x=>[1,2,3], :y=>("a",)), search_response = ""),
           (input_query = "x:[1.0,2,3] y:(\"a\",) z:", filter_response = Dict(:x=>[1.0,2,3], :y=>("a",)), search_response = ""),
           (input_query = "z:\"a b c\" x:1 free form", filter_response = Dict(:z=>"a b c", :x=>1), search_response = "free form"),
           #(input_query = "", filter_reponse=Dict(), search_response=""),
]

@testset "Input: noop_input_parser" begin
	for query in QUERIES
        fake_request = (query=query.input_query,)
		sq, filt = Garamond.noop_input_parser(env, fake_request)
		@test sq == query.input_query
        @test filt == Dict{String, Any}()
	end
end

@testset "Input: base_parser" begin
	for query in QUERIES
        fake_request = (query=query.input_query, )
		sq, filt = Garamond.base_input_parser(env, fake_request; separator=":")
		@test filt == query.filter_response
		@test sq == query.search_response
	end
end
