module MainGaramond

LOCAL_PACKAGES = expanduser("~/projects/")
push!(LOAD_PATH, LOCAL_PACKAGES)

using Garamond

Base.@ccallable function main_garamond(ARGS::Vector{String})::Cint
	Garamond.start_http_server("web/searchpage.html",9999)
	return 0
end

end
