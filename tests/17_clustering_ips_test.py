import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.cluster import AgglomerativeClustering
from scipy.spatial.distance import pdist
from scipy.cluster.hierarchy import linkage, dendrogram
import os

# === FILE PATHS ===
input_path = "/project/arsef/projects/hypo_ml_2025/tests/test_outputs/ips_test_output/genome_ipa_matrix_normalized.tsv"
output_dir = "/project/arsef/projects/hypo_ml_2025/tests/test_outputs/ips_test_output/"

# Create output directory if it doesn't exist
os.makedirs(output_dir, exist_ok=True)

# === STEP 1: Load the InterProScan matrix ===
df = pd.read_csv(input_path, sep="\t", index_col=0)  # Rows = genomes, Columns = domains

print("Matrix loaded with shape:", df.shape)

# === STEP 2: Standardize the features (mean=0, std=1) ===
scaler = StandardScaler()
X = scaler.fit_transform(df.values)

# === STEP 3: Perform hierarchical clustering ===
condensed_dist = pdist(X, metric="euclidean")
linked = linkage(condensed_dist, method="ward")

# === STEP 4: Plot dendrogram and save ===
plt.figure(figsize=(12, 6))
dendrogram(linked, labels=df.index.to_list(), leaf_rotation=90)
plt.title("Hierarchical Clustering Dendrogram (InterProScan Features)")
plt.xlabel("Genomes")
plt.ylabel("Distance")
plt.tight_layout()

dendrogram_path = os.path.join(output_dir, "dendrogram.png")
plt.savefig(dendrogram_path, dpi=300)
print(f"Dendrogram saved to: {dendrogram_path}")

plt.show()
plt.close()

# === STEP 5: Assign clusters with Agglomerative Clustering ===
n_clusters = 4
agg = AgglomerativeClustering(n_clusters=n_clusters, linkage="ward")
cluster_labels = agg.fit_predict(X)

# === STEP 6: PCA for 2D visualization ===
pca = PCA(n_components=2)
X_pca = pca.fit_transform(X)

# === STEP 7: Plot PCA with cluster labels and save ===
plt.figure(figsize=(8, 6))
scatter = plt.scatter(X_pca[:, 0], X_pca[:, 1], c=cluster_labels, cmap="tab10", s=100, edgecolor='k')
for i, genome in enumerate(df.index):
    plt.text(X_pca[i, 0], X_pca[i, 1], genome, fontsize=8)
plt.title("PCA of Genomes Based on InterProScan Features")
plt.xlabel("PC1")
plt.ylabel("PC2")
plt.grid(True)
plt.tight_layout()

pca_path = os.path.join(output_dir, "pca_plot.png")
plt.savefig(pca_path, dpi=300)
print(f"PCA plot saved to: {pca_path}")

plt.show()
plt.close()

# === STEP 8: Save cluster assignments (optional) ===
cluster_output_path = os.path.join(output_dir, "genome_ips_clusters.tsv")
pd.Series(cluster_labels, index=df.index, name="Cluster").to_csv(cluster_output_path, sep="\t")
print(f"Cluster assignments saved to: {cluster_output_path}")

