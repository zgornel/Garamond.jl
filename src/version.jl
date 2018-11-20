"""
	version()

Returns the current Garamond version using the `Project.toml` and `git`.
If the `Project.toml`, `git` are not available, the version defaults to
an empty string.
"""
function version()
	commit = ""
	date = ""
	try
	    readmethod = x->read(x,String)
		commit = open(`git show --oneline -s`) do x
				readmethod(x)[1:7]
		end
		date = open(`git show -s --format="%ci"`) do x
			readmethod(x)[1:10]
		end
	catch
		commit = "unknown"
		date = "unknown"
	end

    v = ""
    try
        project_file = abspath(joinpath(@__DIR__, "..", "Project.toml"))
        open(project_file) do fid
            for line in eachline(fid)
                if occursin("=", line)
                    id, v = strip.(split(line, "="))
                    id == "version" && break
                end
            end
        end
    catch
    end
	return v, commit, date
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
