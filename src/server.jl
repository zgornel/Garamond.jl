function start_http_server(webpage_file::String, port::Int)
	
	# read Web page
	webpage = read(webpage_file, String)

	# Socket hadling function
	function ws_func(req, client)
		while true
			println("WAITING...")

			# Read from web socket
			query = read(client)
			query = String(copy(query))
			println("RECEIVED QUERY: $query")
			
			# Process query
			print("PROCESSING QUERY...")
			pquery = query_process(query); 
			println(" OK")
			
			# Make search
			print("SEARCHING...")
			etime = @elapsed begin
				bv = parse_books(Book, "/home/zgornel/projects/Garamond.jl/data/Cornel/library_big.tsv", delim='\t', header=true);
				response = matcher(pquery, bv)
			end
			
			rj = JSON.json(build_response(etime, response))
			println(" OK")

			# Write back data 
			if isopen(client)
				write(client, rj)
			else 
				warn("Could not write to Web socket.")
			end
		end
	end



	function http_func(req::Request, res::Response) 
		Response(webpage)
	end
	
	# Start server
	run(Server(HttpHandler(http_func), WebSocketHandler(ws_func)), port)

end



# Function that processes a search query arrived from the webpage
function query_process(query::S where S<:AbstractString)
	qd = JSON.parse(query)
	String.(split(qd["text"], r"(\s|,|\.,|\t)"))
end



# Function that builds the response to a query
function build_response(etime, response)
	return Dict("etime" => etime,
	     	"n_matches" => length(response),
		"matches" => response)
end
