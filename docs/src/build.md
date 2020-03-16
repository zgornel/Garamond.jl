# Building

Garamond apps for the search server and clients can be built by running the `build/build_apps.jl` script. The script will compile  the `gars`, `garc` and `garw` apps 
using [PackageCompiler](https://github.com/JuliaLang/PackageCompiler.jl) and place the compilation results in in `/build/compiled`.
The script will make all necessary checks and install packages needed for the compilation.

!!! tips

    - The script will remove the contents of the `build/compiled` directory, removing any previous compilation output. Make sure the binaries are backed up before re-running the process.
    - The compilation works best on Linux systems with the official binary packages rather than the distribution specific ones. The official julia binaries can be downloaded [here](https://julialang.org/downloads/).

At the end of the compilation process, the `build/compiled` will have the structure:
```
$ tree -L 2 build/compiled                                                                                                                                                       (cc-packagecompiler↑2|✚1)
build/compiled
├── garc
│   ├── bin
│   └── lib
├── gars
│   ├── artifacts
│   ├── bin
│   └── lib
└── garw
    ├── artifacts
    ├── bin
    └── lib

11 directories, 0 files
```
