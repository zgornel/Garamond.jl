#!/bin/julia

# This file must be ran inside the build/ directory of the project. It is assumed that
# the upper directory i.e. ../ is the main project directory where the Project.toml and
# Manifest.toml files reside.
const PROJECT = "\"Garamond\""
const BASEDIR = @__DIR__                                                # base directory
const BUILD_DIR = abspath(joinpath(BASEDIR, "bin"))                     # build directory
const TARGETS = ["gars", "garc", "garw"]                                # files to be compiles
const TARGETS_PATH = abspath.(joinpath.(BASEDIR, "..", TARGETS))        # full path to the targes
const REQUIRED_PACKAGES = ["SnoopCompile", "PackageCompiler"]           # Base required packages
const PACKAGE_REVS = Dict(                                              # Packag revisions/branches/etc
    "PackageCompiler"=>("https://github.com/JuliaLang/PackageCompiler.jl", "master"))


##############
### Checks ###
##############

# Check that the upper directory has a Project.toml and the project is Garamond
project_file = joinpath(BASEDIR, "..", "Project.toml")
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
manifest_file = joinpath(BASEDIR, "..", "Manifest.toml")
if !isfile(manifest_file)
    @warn "$manifest_file for $PROJECT does not exist. Will continue..."
end

@info "Pre-checks complete."

# Build or cleanup directory
if !isdir(BUILD_DIR)
    mkdir(BUILD_DIR)
    @info "Created $BUILD_DIR."
else
    rm(BUILD_DIR, recursive=true, force=true)
    @info "Cleaned up $BUILD_DIR."
end


####################
### Dependencies ###
####################

using Pkg
try
    # Add project depedencies to the required ones
    Pkg.activate("..")
    Pkg.update()
    for pkg in keys(Pkg.installed())
        push!(REQUIRED_PACKAGES, pkg)
    end
catch e
    @warn "Could not read main package dependencies! ($e)"
end
@info "Dependencies are: $REQUIRED_PACKAGES"
Pkg.activate()  # reactivate default environment
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
        if !isfile(target)
            @warn "Could not find $target. Exiting..."
            exit()
        end
    end
    @info "Checks complete."

    using PackageCompiler
    COPY_JULIALIBS = false
    for (i, target) in enumerate(TARGETS_PATH)
        @info "*** Building $(uppercase(TARGETS[i])) ***"
        build_executable(target,
                        builddir=BUILD_DIR,
                        copy_julialibs=COPY_JULIALIBS,
                        optimize="2")  # -O2
    end

    @info "Build complete."
end
