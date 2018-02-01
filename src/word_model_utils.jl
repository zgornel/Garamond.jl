function find_cluster_mean(clmodel, model, treemodel, word::String, n::Int)  
	# Get word cluster
	c::Int = get_cluster(clmodel, word)

        # Calculate cluster mean
	vc = Vector{Float64}(size(model.vectors,1))
	cc::Vector{Int} = clmodel.clusters
	mask = falses(vc)
	mask = cc .== c
	vc = vec(mean(view(model.vectors,:, mask),2))

	# Return most similar word to mean cluster
	idx, _ = knn(treemodel, vc, n+1, true)
	return model.vocab[idx[1:end]]
end



function get_cluster_matrix!(Mc, clmodel, model)
	# Pre-allocate
	uc = unique(clmodel.clusters)

	# Fill matrix with mean vector of every cluster
	for (i,ic) in enumerate(uc)
		mask = clmodel.clusters .== ic
		Mc[:,i] = mean(view(model.vectors, :,mask),2)
	end
	return Mc
end

function get_cluster_matrix(clmodel, model)
	m = size(model.vectors,1)
	n = length(unique(clmodel.clusters))
	Mc = zeros(m,n)
	get_cluster_matrix!(Mc, clmodel, model)
	return Mc
end



function find_close_clusters(clmodel, model, word, n)
	# Find mean of all clusters
	m = size(model.vectors,1)
	uc = unique(clmodel.clusters)
	mcm = zeros(m, length(uc))
	get_cluster_matrix!(mcm, clmodel, model)
	
	# Find closest clusters
	wm = Matrix(get_vector(model, word)')'
	close_clusters = sortperm(vec(pairwise(Euclidean(), mcm, wm)))
	return uc[close_clusters[1:n]]
end


function path(clmodel, model, fv, Mc, word1, word2; κ::Float64=1.0, δ::Int=1 )
	#Mc = get_cluster_matrix(clmodel,model)
	D = 1-(MLKernels.kernelmatrix(MLKernels.ColumnMajor(),MLKernels.LinearKernel(), Mc)-1.0);
	minD = minimum(D)
	maxD = maximum(D)
	D = (D.-minD)./(maxD-minD)
	D[D.>=κ] = 0
	G = Graph(D)
	src_c = get_cluster(clmodel,word1)
	dst_c = get_cluster(clmodel,word2)
	if src_c == dst_c 
		info("Words in the same cluster.")
		path = [src_c]
		return nothing
	else
		@time path_graph = LightGraphs.a_star(G, src_c, dst_c, D)
	end

	if isempty(path_graph)
		info("No connection found.")
	else
		nv = length(path_graph)
		path = Vector{Int}(nv+1)
		path[1] = path_graph[1].src
		if nv > 1
			for i in 2:length(path_graph)
				path[i] = path_graph[i].src
			end
		end
		path[end] = path_graph[end].dst
		# Print path
		println("[BEGIN] $word1 --\\")
		t = "\t"
		for cl in path
			pos_cl = find(clmodel.clusters .== cl)
			descriptors = model.vocab[pos_cl][sortperm(fv[pos_cl],rev=true)]
			#descriptors = filter(x->!isupper(x[1]), descriptors)
			println("$t [$cl] --> $(descriptors[1:min(δ, length(descriptors))])")
			t*="\t"
		end
		println("$t [END] \\--$word2")
	end
	return nothing
end






#freqs = zeros(Int,length(model.vocab));
#for i in 1:length(model.vocab)
#	freqs[i] = try getindex(frequencies, model.vocab[i]) catch 0 end
#	#@show i
#end


# Example
#
#kandinsky_clusters = find_close_clusters(clmodel, model, "Kandinsky", 5)^C
#
#for cl in kandinsky_clusters
#	pos_cl = find(clmodel.clusters .== cl)
#	descriptors = model.vocab[pos_cl][sortperm(freqs[pos_cl],rev=true)]
#	descriptors = filter(x->!isupper(x[1]), descriptors)[1:5]
#	println("Cluster $cl, descriptor: $descriptors")
#end
#"""

