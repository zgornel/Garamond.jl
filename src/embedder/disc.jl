"""
Distributed Co-occurence (DisC) structure for
document embedding using word vectors.

# References
  * [Arora et al. ICLR 2018 "A compressed sensing
     view of unsupervised text embeddings, bag-on-n-grams
     and LSTMs"](https://openreview.net/pdf?id=B1e5ef-C-)
"""
struct DisCEmbedder{S,T} <: WordVectorsEmbedder{S,T}
    embeddings::EmbeddingsLibrary{S,T}
    n::Int
end

function DisCEmbedder(embeddings::EmbeddingsLibrary{S,T};
                      n::Int=2) where {T<:AbstractFloat, S<:AbstractString}
    return DisCEmbedder(embeddings, n)
end


# Dimensionality function
function dimensionality(embedder::DisCEmbedder)
    # Embedding corresponding to each n-gram embedding
    # concatenated vertically
    return embedder.n * size(embedder.embeddings)[1]
end

# Sentence embedding function - returns a `embedder.dim`×1 matrix
function sentences2vec(embedder::DisCEmbedder,
                       document_embedding::Vector{Matrix{T}};
                       kwargs...) where {S,T}
    if isempty(document_embedding)
        return zeros(T, dimensionality(embedder), 0)
    else
        return distributed_cooccurence(document_embedding,
                                       embedder.n,
                                       dimensionality(embedder))
    end
end

function distributed_cooccurence(document_embedding::Vector{Matrix{T}},
                                 n::Int,
                                 dim::Int) where {T<:AbstractFloat}
    # Pre-allocate output embeddings
    X = zeros(T, dim, length(document_embedding))
    m = Int(dim/n)
    @inbounds @simd for j in 1:length(document_embedding)
        for k in 1:n
            # For each column `j`, `m` values are filled by
            # the inner loop with the `k`-gram embeddings
            X[(k-1)*m+1:k*m, j] = k_gram_prodsum_embedding(document_embedding[j], k)
        end
    end
    return X
end

function k_gram_prodsum_embedding(A::Matrix{T}, k::Int) where {T}
	n = size(A, 2)		# number of embedded words
	k = clamp(k, 1, n)  # so it does not fail if too few embeddings
	X = zeros(T, size(A, 1), n-k+1)  # output
	col = 1
	@inbounds @simd for j in 1:n-k+1
        # Multiply `k` 'consecutive' embeddings element-wise
        X[:, col] = prod(A[:,j:j+k-1], dims=2)
        col+= 1
	end

	# Add all embedding products together element-wise and return
    return 1/k * vec(sum(X, dims=2))
end
