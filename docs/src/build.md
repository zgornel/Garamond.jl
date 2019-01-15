# Building

Garamond executables and libraries can be built by running the `build/make.jl` script. The script has to be run from inside the `build` directory. It will perform the following operations:
 - check to ensure that it is being ran from the build directory of the Garamond project
 - check that the source code of the targets is present
 - create or empty the build output directory
 - download and install the `PackageCompiler` and `SnoopCompile` packages
 - download and install all project dependencies into the default Julia environment
 - build the executables and libraries for `gars`, `garc` and `garw`.
 - place the output in the `build/bin` directory.

**Note** The script will remove the contents of the `build/bin` directory, removing any previous compilation output.

At the end of the compilation process, the `build/bin` directory will contain:
```
$ tree -L 1 ./build/bin
./build/bin
├── cache_ji_v1.0.3
├── garc
├── garc.a
├── garc.so
├── gars
├── gars.a
├── gars.so
├── garw
├── garw.a
└── garw.so

1 directory, 9 files
```

A sample output of running the script (this output may change in time):
```
$ ./make.jl
[ Info: Checks complete.
[ Info: Cleaned up /home/zgornel/projects/Garamond.jl/build/bin.
[ Info: Dependencies are: ["SnoopCompile", "PackageCompiler", "Statistics", "Glowe", "LightGraphs", "Test", "Random", "StringAnalysis", "ConceptnetNumberbatch", "NearestNeighbors", "HTTP", "DelimitedFiles", "LinearAlgebra", "JSON", "DataStructures", "Word2Vec", "Distances", "SparseArrays", "Unicode", "ProgressMeter", "HNSW", "BKTrees", "Glob", "Languages", "StringDistances", "Dates", "Sockets", "Logging", "ArgParse"]
  Updating registry at `~/.julia/registries/General`
  Updating git-repo `https://github.com/JuliaRegistries/General.git`
  Updating git-repo `https://github.com/zgornel/Word2Vec.jl`
  Updating git-repo `https://github.com/zgornel/Distances.jl`
  Updating git-repo `https://github.com/zgornel/HNSW.jl`
 Resolving package versions...
  Updating `~/.julia/environments/v1.0/Project.toml`
 [no changes]
  Updating `~/.julia/environments/v1.0/Manifest.toml`
 [no changes]
[ Info: Installed dependencies.
[ Info: *** Building GARS ***
Julia program file:
  "/home/zgornel/projects/Garamond.jl/gars"
C program file:
  "/home/zgornel/.julia/packages/PackageCompiler/jBqfm/examples/program.c"
Build directory:
  "/home/zgornel/projects/Garamond.jl/build/bin"
WARNING: could not import Base.endof into StringDistances
┌ [2019-01-19 21:14:16][WARN][gars:66] At least one data configuration file has to be provided
└ through the -d option. Exiting...
All done
[ Info: *** Building GARC ***
Julia program file:
  "/home/zgornel/projects/Garamond.jl/garc"
C program file:
  "/home/zgornel/.julia/packages/PackageCompiler/jBqfm/examples/program.c"
Build directory:
  "/home/zgornel/projects/Garamond.jl/build/bin"
┌ Warning:  is not a proper UNIX socket. Exiting...
└ @ Main.GaramondCLIClient ~/projects/Garamond.jl/garc:165
All done
[ Info: *** Building GARW ***
Julia program file:
  "/home/zgornel/projects/Garamond.jl/garw"
C program file:
  "/home/zgornel/.julia/packages/PackageCompiler/jBqfm/examples/program.c"
Build directory:
  "/home/zgornel/projects/Garamond.jl/build/bin"
┌ Warning: Wrong web-socket port value 0 (default is 0). Exiting...
└ @ Main.GaramondWebClient ~/projects/Garamond.jl/garw:74
All done
[ Info: Build complete.
```
