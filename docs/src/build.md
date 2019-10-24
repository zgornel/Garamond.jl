# Building

Garamond executables and libraries can be built by running the `build/make.jl` script. The script has to be run from inside the `build` directory. It will perform the following operations:
 - check to ensure that it is being ran from the build directory of the Garamond project
 - check that the source code of the targets is present
 - create or empty the build output directory
 - download and install the `PackageCompiler` and `SnoopCompile` packages
 - download and install all project dependencies into the default Julia environment
 - build the executables and libraries for `gars`, `garc` and `garw`.
 - place the output in the `build/bin` directory.

!!! note

    The script will remove the contents of the `build/bin` directory, removing any previous compilation output.

At the end of the compilation process, the `build/bin` directory will contain:
```
$ tree -L 1 ./build/bin
./bin
├── garc
├── garc.a
├── garc.so
├── gars
├── gars.a
├── gars.so
├── garw
├── garw.a
└── garw.so

0 directories, 9 files
```

A sample output of running the script (this output may change in time):
```
$ ./make.jl
[ Info: Pre-checks complete.
[ Info: Cleaned up /home/zgornel/projects/Garamond.jl/build/bin.
Activating environment at `~/projects/Garamond.jl/Project.toml`
  Updating registry at `~/.julia/registries/General`
  Updating git-repo `https://github.com/JuliaRegistries/General.git`
  Updating git-repo `https://github.com/zgornel/HNSW.jl.git`
 Resolving package versions...
  Updating `~/projects/Garamond.jl/Project.toml`
 [no changes]
  Updating `~/projects/Garamond.jl/Manifest.toml`
 [no changes]
[ Info: Dependencies are: ["SnoopCompile", "PackageCompiler", "JuliaDB", "Statistics", "DispatcherCache", "Glowe", "LightGraphs", "Random", "StringAnalysis", "PooledArrays", "ConceptnetNumberbatch", "NearestNeighbors", "HTTP", "DelimitedFiles", "LinearAlgebra", "Memento", "JSON", "DataStructures", "Word2Vec", "Distances", "SparseArrays", "Unicode", "ProgressMeter", "HNSW", "EmbeddingsAnalysis", "BKTrees", "Glob", "Languages", "StringDistances", "Dates", "Dispatcher", "QuantizedArrays", "Sockets", "Logging", "TSVD", "ArgParse"]
Activating environment at `~/.julia/environments/v1.2/Project.toml`
  Updating registry at `~/.julia/registries/General`
  Updating git-repo `https://github.com/JuliaRegistries/General.git`
  Updating git-repo `https://github.com/JuliaLang/PackageCompiler.jl`
  Updating git-repo `https://github.com/zgornel/HNSW.jl`
 Resolving package versions...
  Updating `~/.julia/environments/v1.2/Project.toml`
 [no changes]
  Updating `~/.julia/environments/v1.2/Manifest.toml`
 [no changes]
[ Info: Installed dependencies.
[ Info: Checks complete.
[ Info: *** Building GARS ***
Julia program file:
  "/home/zgornel/projects/Garamond.jl/gars"
C program file:
  "/home/zgornel/.julia/packages/PackageCompiler/tk9TX/examples/program.c"
Build directory:
  "/home/zgornel/projects/Garamond.jl/build/bin"
Activating environment at `~/projects/Garamond.jl/Project.toml`
┌ Info: ~ GARAMOND ~ v"0.2.0" commit: 55dd103 (2019-10-23)
└ @ Main.##anon_module#371.GaramondServer /home/zgornel/projects/Garamond.jl/gars:68
┌ [2019-10-19 10:57:14][WARN][gars:99] At least a UNIX-socket, WEB-socket port or HTTP port
│ have to be specified. Use the -u, -w or -p options.
└ Exiting...
```
