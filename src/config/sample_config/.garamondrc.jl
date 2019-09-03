# This file should be placed in the user home directory and named '.garamondrc.jl'
# for the statements in it to take effect.
#
# Note: Any modification of this file will trigger a re-compilation of
#       Garamond as the file is directly compiled into the engine.
const PDFTOTEXT_PROGRAM = "/usr/bin/pdftotext"  # program to convert PDFs to text
const MAX_EDIT_DISTANCE = 1  # maximum edit distance for which to return suggestions
const MAX_MATCHES = 1_000  # maximum number of matches that can be retrned
const MAX_SUGGESTIONS = 1  # maximum number of overall suggestions
