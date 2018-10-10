#!/bin/julia

# It is assumed that this file is located in <Garamond dirctory>/build
const BUILD_DIR = abspath(joinpath(@__DIR__, "bin"))
const GARAMOND_MAIN_FILE = "garamondmain.jl"
const GARAMOND_MAIN_PATH = abspath(joinpath(@__DIR__, "..", "src",
                                            GARAMOND_MAIN_FILE))
JULIAC_JL = abspath(joinpath(@__DIR__, "juliac.jl"))
using Pkg
Pkg.activate(abspath(joinpath(@__DIR__, "..")))
run(`julia $JULIAC_JL -vosej $GARAMOND_MAIN_PATH -O 2 -d $BUILD_DIR`)
