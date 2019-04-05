# Engine configuration
function load_engine_config(filename::String=DEFAULT_GARAMONDRC_FILE)
    if isfile(filename)
        try
            command = "include(\"$filename\")"
            Garamond.eval(Meta.parse(command))
            @debug "Parsed and evaluated $filename."
        catch
            @warn """There was a problem evaluating $filename.
                     Assuming engine defaults."""
        end
    end
end
# Run the engine config loader
load_engine_config()
# Define the variables
SYMBOLS = Dict(:PDFTOTEXT_PROGRAM => DEFAULT_PDFTOTEXT_PROGRAM,
               :DOCUMENT_TYPE => DEFAULT_DOCUMENT_TYPE,
               :MAX_EDIT_DISTANCE => DEFAULT_MAX_EDIT_DISTANCE,
               :MAX_MATCHES => DEFAULT_MAX_MATCHES,
               :MAX_SUGGESTIONS => DEFAULT_MAX_SUGGESTIONS,
               :MAX_CORPUS_SUGGESTIONS => DEFAULT_MAX_CORPUS_SUGGESTIONS,
               :RESULT_AGGREGATION_STRATEGY => DEFAULT_RESULT_AGGREGATION_STRATEGY)
for (symbol, default_value) in SYMBOLS
    if !isdefined(Garamond, symbol)
        if default_value isa AbstractString
            statement = "const $symbol=\"$default_value\""
        elseif default_value isa Number
            statement = "const $symbol=$default_value"
        elseif default_value isa Symbol
            statement = "const $symbol=:$default_value"
        elseif default_value isa Type
            statement = "const $symbol=$default_value"
        else
            statement = ""  # silently ignore other types
        end
        Garamond.eval(Meta.parse(statement))
    end
end
