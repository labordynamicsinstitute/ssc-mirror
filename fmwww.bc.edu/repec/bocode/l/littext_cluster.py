"""littext_cluster: cluster construct embeddings into synonym groups.

The output is a canonical_form per construct: within each cluster, the most
frequent surface form is chosen as the canonical label.
"""

from __future__ import annotations

import numpy as np
import pandas as pd


SIMILARITY_FLOOR = 0.65


def _split_loose_clusters(labels: np.ndarray, emb: np.ndarray, floor: float) -> np.ndarray:
    """Split any cluster whose min within-cluster cosine similarity < floor.
    """
    out = labels.copy()
    next_label = int(out.max()) + 1 if len(out) and out.max() >= 0 else 0
    for cl in np.unique(out):
        if cl < 0:
            continue
        idx = np.where(out == cl)[0]
        if len(idx) < 2:
            continue
        sub = emb[idx]
        sim = sub @ sub.T
        # Build adjacency: i and j are connected iff sim[i,j] >= floor
        adj = sim >= floor
        # Find connected components by union-find
        parent = list(range(len(idx)))
        def find(x):
            while parent[x] != x:
                parent[x] = parent[parent[x]]
                x = parent[x]
            return x
        def union(a, b):
            ra, rb = find(a), find(b)
            if ra != rb:
                parent[ra] = rb
        for i in range(len(idx)):
            for j in range(i + 1, len(idx)):
                if adj[i, j]:
                    union(i, j)
        # Group local indices by root, assign new labels to each component
        comps = {}
        for i in range(len(idx)):
            comps.setdefault(find(i), []).append(i)
        comps_list = list(comps.values())
        if len(comps_list) <= 1:
            # Cluster already coherent
            continue
        # First component keeps the original label; the rest get new labels
        for k, comp in enumerate(comps_list):
            new_lbl = cl if k == 0 else next_label
            if k > 0:
                next_label += 1
            for local_i in comp:
                out[idx[local_i]] = new_lbl
    return out


def cluster_constructs(constructs_df: pd.DataFrame, embeddings: np.ndarray) -> pd.DataFrame:
    """Add cluster_id and canonical_form columns to constructs_df."""
    if len(constructs_df) == 0:
        constructs_df = constructs_df.copy()
        constructs_df["cluster_id"] = pd.Series(dtype="int64")
        constructs_df["canonical_form"] = pd.Series(dtype="object")
        return constructs_df

    import hdbscan

    n = len(constructs_df)
    
    # The scaling rule produced over-merged mega-clusters on small corpora.
    min_cs = 2
    if n <= 2000:
        sim = embeddings @ embeddings.T
        dist = np.clip(1.0 - sim, 0.0, 2.0).astype(np.float64)
        clusterer = hdbscan.HDBSCAN(metric="precomputed", min_cluster_size=min_cs, min_samples=1)
        labels = clusterer.fit_predict(dist)
    else:
        clusterer = hdbscan.HDBSCAN(metric="euclidean", min_cluster_size=min_cs, min_samples=1)
        labels = clusterer.fit_predict(embeddings)

    labels = _split_loose_clusters(labels, embeddings, floor=SIMILARITY_FLOOR)

    out = constructs_df.copy().reset_index(drop=True)
    out["cluster_id"] = labels.astype(int)

    max_label = int(out["cluster_id"].max()) if (out["cluster_id"] >= 0).any() else -1
    next_id = max_label + 1
    new_labels = out["cluster_id"].tolist()
    for i, lbl in enumerate(new_labels):
        if lbl == -1:
            new_labels[i] = next_id
            next_id += 1
    out["cluster_id"] = new_labels

    canon = (
        out.sort_values(["cluster_id", "freq_doc"], ascending=[True, False])
           .groupby("cluster_id", as_index=False)
           .first()[["cluster_id", "surface_form"]]
           .rename(columns={"surface_form": "canonical_form"})
    )
    out = out.merge(canon, on="cluster_id", how="left")
    return out
