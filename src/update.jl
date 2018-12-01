"""
    update(searcher)

Updates a Searcher from using its SearchConfig.
"""
#TODO(Corneliu): Make this efficient
function update(searcher::T) where T<:AbstractSearcher
    sconf = searcher.config
    @debug "Updating searcher $(sconf.id)..."
    return build_searcher(sconf)::T
end

function update(srchers::T) where T<:AbstractVector
    return update.(srchers)::T
end
