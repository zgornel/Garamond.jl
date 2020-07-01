using Test
using Random
using JuliaDB
using Garamond

tbl = table((y = rand(10),
             x = collect(1:10),
             z = [randstring(1) for _ in 1:10]);
            pkey=:x)

env = (dbdata=tbl, id_key=:x, config_path=nothing)

QUERIES = [(input_query = "this is a query", filter_response = Dict{Symbol,Any}(), search_response = "this is a query"),
           (input_query = "search token x:10 y:1 z:\"a\"", filter_response = Dict(:x=>10, :y=>1.0, :z=>"a"), search_response = "search token"),
           (input_query = "x:[1,2,3] y:(\"a\",) z:", filter_response = Dict(:x=>[1,2,3], :y=>("a",)), search_response = ""),
           (input_query = "x:[1.0,2,3] y:(\"a\",) z:", filter_response = Dict(:x=>[1.0,2,3], :y=>("a",)), search_response = ""),
           (input_query = "z:\"a b c\" x:1 free form", filter_response = Dict(:z=>"a b c", :x=>1), search_response = "free form"),
           (input_query = "", filter_response=Dict(), search_response=""),
]

@testset "Input: noop_input_parser" begin
	for query in QUERIES
        fake_request = (query=query.input_query,)
		sq, filt = Garamond.noop_input_parser(env, fake_request)
        @test filt == Dict{Symbol, Any}()
		@test sq == query.input_query
	end
end

@testset "Input: base_input_parser" begin
	for query in QUERIES
        fake_request = (query=query.input_query, )
		sq, filt = Garamond.base_input_parser(env, fake_request; separator=":")
		@test filt == query.filter_response
		@test sq == query.search_response
	end
end

@testset "Input: pre_parser" begin
    PREPARSER_DATA = [("noop_input_parser>", Garamond.noop_input_parser),
                      ("base_input_parser>", Garamond.base_input_parser),
                      ("pre_parser> base_input_parser>", Garamond.pre_parser),
                      ("pre_parser> pre_parser  >", Garamond.pre_parser)]

    for (parser_specification, parser_function) in PREPARSER_DATA
        for query in QUERIES
            preparser_query = parser_specification * query.input_query
            fake_request = Garamond.InternalRequest(query=preparser_query,
                                                    input_parser=:pre_parser,
                                                    searchable_filters=[])
            sq, filt = parse_input(env, fake_request)
            if occursin("base_input_parser", parser_specification)
                # final parser is the base_input_parser
                @test filt == query.filter_response
                @test sq == query.search_response
            elseif occursin("noop_input_parser", parser_specification)
                # final parser is the noop_parser
                @test filt == Dict{Symbol, Any}()
		        @test sq == query.input_query
            else
                # Using DEFAULT_INPUT_PARSER_NAME as end parser
                # (it is already tested), just test that parsing works
                @test filt isa Dict{Symbol, Any}
                @test sq isa String
            end
        end
    end
end
