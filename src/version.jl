"""
	version()

Returns the current Garamond version using the `Project.toml` and `git`.
If the `Project.toml`, `git` are not available, the version defaults to
an empty string.
"""
function version()
    commit = DEFAULT_VERSION_COMMIT
    date = DEFAULT_VERSION_DATE
    ver = DEFAULT_VERSION
    try
        root_path = "/" * joinpath(split(pathof(Garamond), "/")[1:end-2]...)

        # Check that the current git repository is the garamond one
        _check_commit = split(Garamond.DEFAULT_VERSION_COMMIT, "*")[1]
        cd(root_path)
        @assert occursin("master", read(pipeline(`git branch --contains $(_check_commit)`,
                                                 stderr=devnull), String))
        # Try reading the latest commit and date
        gitstr = read(pipeline(`git show --oneline -s --format="%h%ci"`, stderr=devnull), String)
        commit = gitstr[1:7]
        date = gitstr[8:17]
        # Try reading the version from the Project.toml file
        project_file = "Project.toml"
        open(project_file) do fid
            for line in eachline(fid)
                if occursin("=", line)
                    id, ver = strip.(split(line, "="))
                    id == "version" && break
                end
            end
        end
    catch
        # do nothing
    end
	return ver, commit, date
end


"""
    printable_version()

Returns a pretty version string that includes the git commit and date.
"""
function printable_version()
    ver, commit, date = version()
    vstr = ""
    if !isempty(ver)
        vstr = vstr * "v"*ver
    end
    if !isempty(commit)
        vstr = vstr * " commit: $commit"
    end
    if !isempty(date)
        vstr = vstr * " ($date)"
    end
    return vstr
end
