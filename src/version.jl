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
        commit = read(`git show --oneline -s`, String)[1:7]
        date = read(`git show -s --format="%ci"`, String)[1:10]
    catch
        # do nothing
    end
    try
        project_file = abspath(joinpath(@__DIR__, "..", "Project.toml"))
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
