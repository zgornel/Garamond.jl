function start_http_server(webpage_file::String, data_config_file::String, http_port::Int)
	
	# Read Web page
	if isempty(webpage_file)
		webpage = default_webpage()
	else
		webpage = read(webpage_file, String)
	end

	# Socket hadling function
	function ws_func(req, client)
	
		crpra = load_corpora(data_config_file)
	
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
				##############################################
				#####         Where it all begins        #####
				response, suggestions = search(crpra, pquery)
				##############################################
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

	# Function called when a HTTP request is received
	function http_func(req::Request, res::Response) 
		Response(webpage)
	end
	
	# Start server
	run(Server(HttpHandler(http_func), WebSocketHandler(ws_func)), http_port)
end



# Function that processes a search query arrived from the webpage
function query_process(query::S where S<:AbstractString)
	qd = JSON.parse(query)
	prepare!(qd["text"], QUERY_STRIP_FLAGS)
end



# Function that builds the response to a query
function build_response(etime, response)
	ncrps = length(response)  #  number of corpora
	nmatch = sum(map(length, values(response)))  # number of matches
	ncrpsm = sum(map(!isempty, values(response)))  # number of corpora with matches
	return Dict("etime" => etime,
		    "n_matches" => nmatch,
		    "n_corpora" => ncrps,
		    "n_corpora_match" => ncrpsm,
		    "matches" => response)
end



# Function that returns the default webpage
default_webpage = ()->return "
	<!doctype html>
	<html>
	<head>
	    <title>~ Garamond Search ~ by 0x0α Research </title>
	    <style>
		form {
			width:500px;
			margin:100px auto;
		}
		.search {
			width:300px;
			padding:8px 30px;
			background:rgba(100, 100, 100, 0.2);
			border:1px solid #000000;
			font-family: \'Times New Roman\';
			font-size: 15px;
		}
		.button {
			position:relative;
			padding:8px 25px;
			left:8px;
			border:1px solid #000000;
			background-color:#a0cfff;
			color:#000000;
			font-family: \'Times New Roman\';
			font-size: 15px;
		}
		.button:hover  {
			background-color:#fafafa;
			color:#000000;
		}
		#pby {
			font-family: \'Times New Roman\';
			font-size: 12px;
		}
		
		#search_results {
			font-family: \'Times New Roman\';
			font-size: 14px;
		}
	    </style>
	</head>
	<body>	
		<!-- search section -->
		<div id=\"search_header\" style=\"position:fixed;float:left;top:0;height:50px;width:100%;\">
			<form id=\"search_box\">
				<input id=\"search_box_txt\" type=\"text\" class=\"search\" placeholder=\"Search...\" required>
				<input id=\"search_box_button\" type=\"button\" class=\"button\" value=\"Search\">
				<p id=\"pby\" align=\"right\"> powered by 
				<!--	<img alt=\"0x0α Research\" src=\"img/logo.png\" style=\"float:center;max-width:15%\"> -->
					<img alt=\"0x0α Research\" src=\"https://s9.postimg.org/kmiy2ofbj/logo.png\" style=\"float:center;max-width:15%\">
				</p>
			</form>
		</div>
		<!-- results section -->
		<div id=\"search_results\" style=\"position:fixed;float:left;left:100px;top:200px\">
		</div>

	<script type=\"text/javascript\">
		//document.addEventListener(\'DOMContentLoaded\', function (){
		//}, \'false\');
		
		// Global variables
		var connection = new WebSocket(\'ws://localhost:9999\'); 
		var search_results = document.getElementById(\"search_results\");
		
		// When socket connection opened i.e. on page load
		connection.onopen = function(e){ console.log(\"websocket ok\")};

		

		//When receiving socket message
		connection.onmessage = function(r){
			window.lastmessage = r;
			console.log(\"Response received!\");
			
			// Response example: { \"etime\": 0.2,
			//			\"n_matches\": 3 ,
			//			\"matches\":<list of book Dicts>}
			jr = JSON.parse(r.data);

			// Process JSON data (access with jr.etime, etc)
			var search_time = jr.etime;
			var n_matches = jr.n_matches;
			var matches = jr.matches;
			
			results_text = \"<p>Elapsed search time: <b>\" + jr.etime + \"</b>s.</br></p>\";
			results_text += \"<br>\";
			results_text += \"<p>Found \" + jr.n_matches + \" results in \" + jr.n_corpora_match +
					\" corpora (out of a total of \" + jr.n_corpora + \"):</p>\";
			results_text += \"<p>\";

			for (let crps_id in jr.matches){
				let crps_matches = jr.matches[crps_id]  // individual corpus matches
				results_text +=\"<p><b>i\" + crps_id +\"</b></br></p>\"
				for (i=0; i < crps_matches.length; i++){
					results_text += \"&emsp;<i> \\\"\" +
						crps_matches[i].name + \"\\\"</i>\" + \" by \" +
						crps_matches[i].author + \" <b>\" +
						crps_matches[i].publisher + \"</b>, \" +
						crps_matches[i].published_year + \"<br>\"
				}
			}
			results_text += \"</p>\"
			search_results.innerHTML = results_text;
		}


		// Send message function
		function sendMessage(q){
			console.log(\"Sending message...\");
			// Create JSON query
			var jq = {
				type: \"unknown\",
				text: q,
				date: Date()
			}
			connection.send(JSON.stringify(jq));
		}

		

		// Variables for the search box and button
		var search_box = document.getElementById(\"search_box\"),
		    search_box_button = document.getElementById(\"search_box_button\"),
		    serch_box_txt = document.getElementById(\"search_box_txt\");



		// When clicking the button
		search_box_button.onclick = function(){ 
			search_box_txt.value = \"\"
			sendMessage(search_box_txt.value);
		}; 
		
		// When submitting the form
		search_box.onsubmit = function(){ 
			sendMessage(search_box_txt.value);
			search_box_txt.value = \"\"
			return false;
		};

		// Close web socket when page is reloaded
		window.onunload = function() {
			window.alert(\"CLOSING\");
			console.log(\"closing web socket...\");
			connection.close();
		};
	</script>

	</body>

	</html>
	"
