import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.cluster import AgglomerativeClustering
from scipy.spatial.distance import pdist
from scipy.cluster.hierarchy import linkage, dendrogram
import os

# must be inside the sklearn-env (scinet) to run this script (or have the packages installed in your own env)

version = "1" # file version for output naming (mainly for testing purposes)

# === FILE PATHS ===
input_path = f"/project/arsef/projects/hypo_ml_2025/tests/test_outputs/normalized_matrices_test/combined/combined_normalized_features_{version}.tsv"
output_dir = f"/project/arsef/projects/hypo_ml_2025/tests/test_outputs/clustering/clustering_v{version}"

# Create output directory if it doesn't exist
os.makedirs(output_dir, exist_ok=True)

# Load the combined matrix 
df = pd.read_csv(input_path, sep="\t", index_col=0)  # Rows = genomes, Columns = combined features
print("Combined matrix loaded with shape:", df.shape)

# Standardize the features (mean=0, std=1)
scaler = StandardScaler()
X = scaler.fit_transform(df.values)

# Perform hierarchical clustering
condensed_dist = pdist(X, metric="euclidean")
linked = linkage(condensed_dist, method="ward")

# Plot dendrogram and save 
plt.figure(figsize=(12, 6))
dendrogram(linked, labels=df.index.to_list(), leaf_rotation=90)
plt.title("Hierarchical Clustering Dendrogram (Combined Features)")
plt.xlabel("Genomes")
plt.ylabel("Distance")
plt.tight_layout()

dendrogram_path = os.path.join(output_dir, f"combined_dendrogram_{version}.png")
plt.savefig(dendrogram_path, dpi=300)
print(f"Dendrogram saved to: {dendrogram_path}")

plt.show()
plt.close()

# Assign clusters with Agglomerative Clustering
n_clusters = 3  # adjust as needed (1 < k < n)
agg = AgglomerativeClustering(n_clusters=n_clusters, linkage="ward")
cluster_labels = agg.fit_predict(X)

# PCA
pca = PCA(n_components=2)
X_pca = pca.fit_transform(X)

# Create a DataFrame for PCA results
pca_df = pd.DataFrame(X_pca, columns=["PC1", "PC2"], index=df.index)
print(pca_df.head())

# Explained variance
explained_var = pca.explained_variance_ratio_
print(f"PC1 explains {explained_var[0]:.2%} of variance")
print(f"PC2 explains {explained_var[1]:.2%} of variance")

# Get loadings: how much each original feature contributes to PC1 and PC2
loadings = pd.DataFrame(
    pca.components_.T,
    index=df.columns,
    columns=["PC1_loading", "PC2_loading"]
)

# Plot PCA with cluster labels and save 
plt.figure(figsize=(8, 6))
scatter = plt.scatter(X_pca[:, 0], X_pca[:, 1], c=cluster_labels, cmap="tab10", s=100, edgecolor='k')
for i, genome in enumerate(df.index):
    plt.text(X_pca[i, 0], X_pca[i, 1], genome, fontsize=8)
plt.title("Test PCA of Genomes Based on Combined Features")
plt.xlabel("PC1")
plt.ylabel("PC2")
plt.grid(True)
plt.tight_layout()

pca_path = os.path.join(output_dir, f"combined_pca_plot_k{n_clusters}_{version}.png")
plt.savefig(pca_path, dpi=300)
print(f"PCA plot saved to: {pca_path}")

plt.show()
plt.close()

# Save cluster assignments 
cluster_output_path = os.path.join(output_dir, f"combined_genome_clusters_k{n_clusters}_{version}.tsv")
pd.Series(cluster_labels, index=df.index, name="Cluster").to_csv(cluster_output_path, sep="\t")
print(f"Cluster assignments saved to: {cluster_output_path}")

# Save the PCA Coordinates
pca_output_path = os.path.join(output_dir, f"combined_pca_coordinates_k{n_clusters}_{version}.tsv")
pca_df.to_csv(pca_output_path, sep="\t")
print(f"PCA coordinates saved to: {pca_output_path}")

# Save the PCA loadings
loadings_path = os.path.join(output_dir, f"combined_pca_feature_loadings_k{n_clusters}_{version}.tsv")
loadings.to_csv(loadings_path, sep="\t")
print(f"PCA feature loadings saved to: {loadings_path}")