# Main Embedder type, parametrized by S - typeof string used in the word
# embeddings library, in the arious dictionaries/lexicons and T the type
# of Float of the vectors
abstract type AbstractEmbedder{S<:AbstractString, T<:AbstractFloat}  end

# Add the rest of the abstract interface if any below ...
