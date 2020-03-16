#!/bin/julia

# This file must be ran inside the build/ directory of the project. It is assumed that
# the upper directory i.e. ../ is the main project directory where the Project.toml and
# Manifest.toml files reside.
const PROJECT = "\"Garamond\""
const BUILD_DIR = "/" * joinpath(split(@__FILE__, "/")[1:end-1]...)       # root project directory
const PROJECT_DIR = abspath(joinpath(BUILD_DIR, ".."))
const BASE_ENV_PATH = joinpath(ENV["HOME"], ".julia", "environments",
                               "v" * string(Int(Base.VERSION.major)) * "." *
                                     string(Int(Base.VERSION.minor))
                              )
const COMPILED_DIR = "compiled"
const APPS_DIR = "apps"
const APPS_PATH = abspath(joinpath(PROJECT_DIR, APPS_DIR))
const COMPILED_PATH = abspath(joinpath(BUILD_DIR, COMPILED_DIR))        # build directory
const TARGETS = ["gars", "garc", "garw"]                                # files to be compiles
const TARGETS_PATH = abspath.(joinpath.(APPS_PATH, TARGETS))            # full path to the targes
const REQUIRED_PACKAGES = ["PackageCompiler"]                           # required packages for compilation
const PACKAGE_REVS = Dict(                                              # Packag revisions/branches/etc
    #"PackageCompiler"=>("https://github.com/JuliaLang/PackageCompiler.jl", "master"),
    "Languages"=>("https://github.com/JuliaText/Languages.jl", "master")
   )

##############
### Checks ###
##############

# Check that the upper directory has a Project.toml and the project is Garamond
project_file = joinpath(PROJECT_DIR, "Project.toml")
if isfile(project_file)
    local key_name, project_name
    try
        key_name, project_name = strip.(split(readline(project_file), "="))
    catch
        @warn "Something went wrong while parsing the first line of $project_file. Exiting..."
        exit()
    end
    if key_name != "name" || project_name != PROJECT
        @warn "Malformed first line of Project.toml (expected: name=$PROJECT). Exiting..."
        exit()
    end
else
    @warn "$project_file for $PROJECT does not exist. Exiting..."
    exit()
end

# Check for a manifest file, warn if not present
manifest_file = joinpath(PROJECT_DIR, "Manifest.toml")
if !isfile(manifest_file)
    @warn "$manifest_file for $PROJECT does not exist. Will continue..."
end

@info "Pre-checks complete."

# Build or cleanup directory
if !isdir(COMPILED_PATH)
    mkdir(COMPILED_PATH)
    @info "Created $COMPILED_PATH."
else
    rm(COMPILED_PATH, recursive=true, force=true)
    @info "Cleaned up $COMPILED_PATH."
end


####################
### Dependencies ###
####################

using Pkg
try
    # Add project depedencies to the required ones
    Pkg.activate(PROJECT_DIR)
    Pkg.instantiate()
    #for pkg in keys(Pkg.installed())
    #    push!(REQUIRED_PACKAGES, pkg)
    #end
catch e
    @warn "Could not read $PROJECT package dependencies! ($e)"
end

@info "Dependencies are: $REQUIRED_PACKAGES"
Pkg.activate(BASE_ENV_PATH)  # reactivate default environment
Pkg.update()
for pkg in REQUIRED_PACKAGES
    if  !(pkg in keys(Pkg.installed()))
        if pkg in keys(PACKAGE_REVS)
            # Add custom revision, branch etc
            url, rev = PACKAGE_REVS[pkg]
            Pkg.add(PackageSpec(url=url, rev=rev))
        else
            # Add registered version
            Pkg.add(pkg)
        end
    end
end
@info "Installed dependencies."


########################
### Build Executable ###
########################

if length(ARGS) != 0 && ARGS[1] == "--deps-only"
    @info "Skipping build (deps-only)."
else
    # Check that all targets exist
    for target in TARGETS_PATH
        if !isdir(target)
            @warn "Could not find $target. Exiting..."
            exit()
        end
    end
    @info "Checks complete."

    using PackageCompiler
    cd(APPS_PATH)
    Pkg.activate(PROJECT_DIR)
    for (i, target) in enumerate(TARGETS)
        @info "*** Building $(uppercase(target)) ***"
        create_app(target, joinpath(COMPILED_PATH, target), force=true)
    end
    @info "Build complete."
end
