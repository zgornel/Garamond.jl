#!/bin/julia

#############################################
# Garamond script for TCP client operations #
#############################################
module garw

using Logging
using Sockets
using ArgParse
using HTTP


# Function that parses Garamond's web-socket client arguments
function get_web_socket_client_arguments(args::Vector{String})
	s = ArgParseSettings()
	@add_arg_table! s begin
        "--log-level"
            help = "logging level"
            default = "warn"
        "--web-socket-port", "-w"
            help = "WEB socket data communication port"
            arg_type = UInt16
            default = UInt16(0)
        "--web-socket-ip"
            help = "WEB socket data communication IP"
            default = "127.0.0.1"
        "--http-port", "-p"
            help = "HTTP port for the http server"
            arg_type = Int
            default = 8888
        "--web-page"
            help = "Search web page to serve"
            arg_type = String
        "--return-fields"
            help = "List of fields to return (ignores wrong names)"
            nargs = '*'
	end
	return parse_args(args,s)
end


stringvec(vv) = "[" * join(map(v->"\"" * string(v) * "\"", vv), ",") * "]"


# Function that returns the default webpage
function _default_webpage(ws_ip::String, ws_port::UInt16; fields=[])
    return "
	<!doctype html>
	<html>
	<head>
	    <title>~ Garamond Search ~ by 0x0a Research </title>
	    <style>
        html,body{overflow: auto; }
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
				<p id=\"pby\" align=\"right\"> powered by <b>0x0a Research</b></p>
			</form>
		</div>
		<!-- results section -->
		<div id=\"search_results\" style=\"position:fixed;float:left;left:100px;top:200px\">
		</div>

    <script type=\"text/javascript\">
        //document.addEventListener(\'DOMContentLoaded\', function (){
        //}, \'false\');

        // Global variables
        var connection = new WebSocket(\'ws://$ws_ip:$ws_port\');
        var search_results = document.getElementById(\"search_results\");

        // When socket connection opened i.e. on page load
        connection.onopen = function(e){ console.log(\"websocket ok\")};

        //When receiving socket message
        connection.onmessage = function(r){
            window.lastmessage = r;
			console.log(\"Response received!\");

            // Response example: { \"elapsed_time\": 0.2,
            //                     \"n_total_results\": 3 ,
            //                     \"results\":{\"srcher1\":[...], \"srcher2\": [...]}
            jr = JSON.parse(r.data);

            // Process JSON data (access with jr.elapsed_time etc.)
            var search_time = jr.elapsed_time;
            var n_total_results = jr.n_total_results;
            var results = jr.results;
            // NOTE: Suggestions are not supported

            results_text = \"<p>Elapsed search time: <b>\" + jr.elapsed_time + \"</b>s.</br></p>\";
            results_text += \"<p>Found \" + jr.n_total_results + \" results in \" + jr.n_searchers_w_results +
                \" searchers (out of a total of \" + jr.n_searchers + \"):</p>\";
            results_text += \"<p>\";

            for (let _id in jr.results){
                let _result = jr.results[_id]  // individual searcher matches
                // Display id only if there are results
                if (_result.length > 0){
				    results_text +=\"<p><b>\" + _id +\"</b></br></p>\"
                }
                for (let i=0; i < _result.length; i++){
                    results_text += \"&emsp;\"
                    results_text += \"<b>[\" + _result[i][\"score\"] + \"]</b>\" + \" ~ \";
                    for (let field in _result[i]){
                        if (field != \"score\"){
                            results_text += field + \": \" + _result[i][field] + \" \";
                        }
                    }
                    results_text += \"<br>\";
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
                operation: \"search\",
                query: q,
                input_parser: \"base_input_parser\",
                max_matches: 1000,
                response_size: 100,
                search_method: \"exact\",
                max_suggestions: 0,
                return_fields: $(stringvec(fields))
                //date: Date()
                // no custom_weights
            }
            //console.log(jq.return_fields);
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
    </html>"
end


########################
# Main module function #
########################
function julia_main()::Cint
    try
        real_main()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end


function real_main()
    # Parse command line arguments
    args = get_web_socket_client_arguments(ARGS)

    # Logging
    log_levels = Dict("debug" => Logging.Debug,
                      "info" => Logging.Info,
                      "warning" => Logging.Warn,
                      "error" => Logging.Error)
    logger = ConsoleLogger(stdout,
                get(log_levels, lowercase(args["log-level"]), Logging.Info))
    global_logger(logger)

    # Start client
    @info "~ GARAMOND ~ (web-socket client)"
    ws_ip = args["web-socket-ip"]
    ws_port = args["web-socket-port"]
    return_fields = args["return-fields"]

    if ws_port > 0
        # Get web page
        webpage_file = args["web-page"]
        if webpage_file != nothing && isfile(webpage_file)
            webpage = read(webpage_file, String)
        else
            webpage = _default_webpage(ws_ip, ws_port; fields=return_fields)
        end

        # Start HTTP server
        http_port = args["http-port"]
        _handler(request::HTTP.Request) = begin
            try
                return HTTP.Response(200, webpage)
            catch e
                return HTTP.Response(404, "Error: $e")
            end
        end
        http_ip = Sockets.localhost
        @info "Serving page on $http_ip:$http_port"
        HTTP.serve(_handler, http_ip, http_port, readtimeout=0)
    else
        @warn "Wrong web-socket port value $ws_port (default is 0). Exiting..."
    end
    return 0
end


################################
# Start main Garamond function #
################################
if abspath(PROGRAM_FILE) == @__FILE__
    real_main()
end

end  # module
