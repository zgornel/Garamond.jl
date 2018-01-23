function start_http_server(webpage_file::String, port::Int)
	
	# read Web page
	webpage = read(webpage_file, String)

	# Socket hadling function
	function ws_func(req, client)
		while true

			# Read from web socket
			msg = read(client)
			msg = String(copy(msg))
			println("RECEIVED QUERY: $msg")
			
			# Write back data 
			if isopen(client)
				write(client, msg)
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
