"""littext_viz: matplotlib-based figures for littext.

The Stata-native figures (frequency, distribution, trend, confidence) are
produced by _littext_graph.ado directly. This module handles only the figures
that genuinely require a Python plotting stack: the UMAP concept map, the
relationship network, and the cluster dendrogram.

All figures are saved to PNG (300 dpi) and PDF (vector) so that the user has
both raster and publication-quality outputs without re-running the pipeline.
"""

from __future__ import annotations

import os
from typing import Optional

import numpy as np
import pandas as pd

def _save_both(fig, out_stub: str) -> None:
    fig.savefig(out_stub + ".png", dpi=300, bbox_inches="tight")
    fig.savefig(out_stub + ".pdf", bbox_inches="tight")


def _want_static(fmt: str) -> bool:
    return (fmt or "static").strip().lower() in ("static", "both")


def _want_html(fmt: str) -> bool:
    return (fmt or "static").strip().lower() in ("html", "both")


def _save_html(plotly_fig, out_stub: str, embed: str = "selfcontained") -> None:
    """Write a Plotly figure to <out_stub>.html.

    embed='selfcontained' embeds plotly.js in the file (~3.5 MB) so it
    opens offline on any machine -- the right choice for presentations and
    sharing. embed='cdn' produces a small file that loads plotly.js from a
    CDN at view time and therefore needs an internet connection.
    """
    include = True if embed == "selfcontained" else "cdn"
    plotly_fig.write_html(out_stub + ".html", include_plotlyjs=include,
                          full_html=True)


def _html_note(out_stub: str) -> None:
    print('littext: interactive figure saved to "{}.html"'.format(out_stub), flush=True)


def _build_level_map(constructs_df: pd.DataFrame, level: str):
    """Return (rollup_map, applied, note) for the requested hierarchy level.

    rollup_map maps each canonical_form to its rolled ancestor. The
    semantics mirror _lt_remap_canonical in _littext_graph.ado exactly so
    that Stata-native and matplotlib roll-ups agree:

      - level "leaf"  -> identity (no roll-up)
      - level "root"  -> canonical_root (precomputed topmost ancestor)
      - level "<int>" -> ancestor at hierarchy_depth N; a construct at
                         depth d > N is replaced by walking parent_canonical
                         (d - N) steps; constructs at depth <= N are kept.    
    """
    lvl = (level or "leaf").strip().lower()
    if lvl == "leaf":
        return {}, False, ""

    if "canonical_form" not in constructs_df.columns:
        return {}, False, "level() not applied: cached frame lacks canonical_form."

    if lvl == "root":
        if "canonical_root" not in constructs_df.columns:
            return {}, False, "level(root) not applied: cached frame lacks canonical_root."
        m = {}
        for _, row in constructs_df.iterrows():
            cf = row["canonical_form"]
            cr = row.get("canonical_root", "")
            if isinstance(cf, str) and cf:
                m[cf] = cr if (isinstance(cr, str) and cr) else cf
        return m, True, ""

    # Integer level.
    try:
        target_depth = int(lvl)
    except ValueError:
        return {}, False, "level() not applied: unrecognised level '{}'.".format(level)
    if target_depth < 0:
        return {}, False, "level() not applied: level must be non-negative."
    needed = {"parent_canonical", "hierarchy_depth"}
    if not needed.issubset(constructs_df.columns):
        return {}, False, "level({}) not applied: cached frame lacks parent_canonical/hierarchy_depth.".format(target_depth)

    parent_of = {}
    depth_of = {}
    for _, row in constructs_df.iterrows():
        cf = row["canonical_form"]
        if not (isinstance(cf, str) and cf):
            continue
        parent_of[cf] = row.get("parent_canonical", "") or ""
        try:
            depth_of[cf] = int(row.get("hierarchy_depth", 0))
        except (TypeError, ValueError):
            depth_of[cf] = 0

    m = {}
    for cf in parent_of:
        cur = cf
        guard = 0
        while depth_of.get(cur, 0) > target_depth and guard < 1000:
            parent = parent_of.get(cur, "")
            if not parent:
                break
            cur = parent
            guard += 1
        m[cf] = cur
    return m, True, ""


def draw_figure(kind: str, top: int = 20, out_stub: str = "littext_figure",
                weighted: bool = False, level: str = "leaf",
                fmt: str = "static", embed: str = "selfcontained") -> None:
    """Dispatch to the requested figure type using cached pipeline state.   
    """
    from littext_state import load_state
    state = load_state()
    constructs_df = state["constructs_df"]
    embeddings = state["construct_embeddings"]
    relations_df = state["relations_df"]

    lvl = (level or "leaf").strip().lower()

    if kind == "map":
        _draw_concept_map(constructs_df, embeddings, top=top, out_stub=out_stub,
                          level=lvl, fmt=fmt, embed=embed)
    elif kind == "network":
        _draw_network(constructs_df, relations_df, top=top, out_stub=out_stub,
                      weighted=weighted, level=lvl, fmt=fmt, embed=embed)
    elif kind == "dendrogram":
        if lvl != "leaf":
            print("littext: NOTE -- level() does not apply to type(dendrogram); "
                  "its tree is built from cluster distances, not the construct "
                  "hierarchy. Drawing at leaf level.", flush=True)
        _draw_dendrogram(constructs_df, embeddings, top=top, out_stub=out_stub,
                         fmt=fmt, embed=embed)
    elif kind == "cooccurrence":
        if lvl != "leaf":
            print("littext: NOTE -- level() does not apply to type(cooccurrence); "
                  "drawing at leaf level.", flush=True)
        _draw_cooccurrence(constructs_df, relations_df, top=top, out_stub=out_stub,
                           fmt=fmt, embed=embed)
    elif kind == "roles":
        if lvl != "leaf":
            print("littext: NOTE -- level() does not apply to type(roles); "
                  "drawing at leaf level.", flush=True)
        _draw_roles(constructs_df, relations_df, top=top, out_stub=out_stub,
                    fmt=fmt, embed=embed)
    else:
        raise ValueError(f"unknown figure kind: {kind}")


def _draw_concept_map(constructs_df: pd.DataFrame, embeddings: np.ndarray, top: int,
                      out_stub: str, level: str = "leaf", fmt: str = "static",
                      embed: str = "selfcontained") -> None:
    import warnings
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt    
    with warnings.catch_warnings():
        warnings.filterwarnings("ignore", category=UserWarning, module="umap")
        import umap

    if len(constructs_df) < 5:
        # Not enough points for UMAP; draw a placeholder
        fig, ax = plt.subplots(figsize=(8, 6))
        ax.text(0.5, 0.5, "Too few constructs for a concept map\n(need at least 5).",
                ha="center", va="center", fontsize=12)
        ax.set_axis_off()
        _save_both(fig, out_stub)
        plt.close(fig)
        return

    n_neighbors = min(15, max(2, len(constructs_df) - 1))
    with warnings.catch_warnings():
        warnings.filterwarnings("ignore", category=UserWarning, module="umap")
        reducer = umap.UMAP(n_components=2, n_neighbors=n_neighbors, min_dist=0.1, metric="cosine", random_state=42)
        coords = reducer.fit_transform(embeddings)

    cf = constructs_df.copy().reset_index(drop=True)
    cf["x"] = coords[:, 0]
    cf["y"] = coords[:, 1]
    
    rollup_map, applied, note = _build_level_map(constructs_df, level)
    if note:
        print("littext: " + note, flush=True)

    title = "Concept map of extracted constructs (UMAP projection)"
    if applied and rollup_map:
        cf["rolled"] = cf["canonical_form"].map(lambda c: rollup_map.get(c, c))
        wsum = cf.groupby("rolled").apply(
            lambda d: pd.Series({
                "x": np.average(d["x"], weights=d["freq_doc"].clip(lower=1)),
                "y": np.average(d["y"], weights=d["freq_doc"].clip(lower=1)),
                "freq_doc": d["freq_doc"].sum(),
            })
        ).reset_index()
        wsum = wsum.rename(columns={"rolled": "canonical_form"})
        plot_df = wsum
        title += " -- rolled to level({})".format(level)
    else:
        plot_df = cf

    # Group key for coloring: cluster_id at leaf, rolled label otherwise.
    if "cluster_id" in plot_df.columns and not (applied and rollup_map):
        group_key = plot_df["cluster_id"].astype(str).tolist()
    else:
        group_key = plot_df["canonical_form"].astype(str).tolist()

    if _want_html(fmt):
        _plotly_scatter(
            plot_df["x"].tolist(), plot_df["y"].tolist(),
            plot_df["canonical_form"].tolist(),
            plot_df["freq_doc"].tolist(), group_key,
            title, out_stub, embed)

    if not _want_static(fmt):
        return

    fig, ax = plt.subplots(figsize=(10, 8))
    cmap = plt.get_cmap("tab20")
    if "cluster_id" in plot_df.columns and not (applied and rollup_map):
        clusters = plot_df["cluster_id"].unique()
        for k, cl in enumerate(clusters):
            sub = plot_df[plot_df["cluster_id"] == cl]
            ax.scatter(sub["x"], sub["y"], s=20 + 4 * sub["freq_doc"].clip(upper=20),
                       color=cmap(k % 20), alpha=0.7, edgecolors="white", linewidths=0.5)
    else:
        # Rolled view: colour each rolled group distinctly.
        for k, (_, sub) in enumerate(plot_df.groupby("canonical_form")):
            ax.scatter(sub["x"], sub["y"], s=20 + 4 * sub["freq_doc"].clip(upper=20),
                       color=cmap(k % 20), alpha=0.7, edgecolors="white", linewidths=0.5)
    # Label top-`top` constructs by frequency
    top_cf = plot_df.sort_values("freq_doc", ascending=False).head(top)
    for _, row in top_cf.iterrows():
        ax.annotate(row["canonical_form"], (row["x"], row["y"]),
                    fontsize=9, alpha=0.85, xytext=(3, 3), textcoords="offset points")
    ax.set_title(title)
    ax.set_xlabel("UMAP-1")
    ax.set_ylabel("UMAP-2")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    _save_both(fig, out_stub)
    plt.close(fig)


def _draw_network(constructs_df: pd.DataFrame, relations_df: pd.DataFrame, top: int,
                  out_stub: str, weighted: bool = False, level: str = "leaf",
                  fmt: str = "static", embed: str = "selfcontained") -> None:
    """Force-directed network of candidate relationships.
    """
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import networkx as nx

    if len(relations_df) == 0:
        fig, ax = plt.subplots(figsize=(8, 6))
        ax.text(0.5, 0.5, "No candidate relationships to plot.", ha="center", va="center", fontsize=12)
        ax.set_axis_off()
        _save_both(fig, out_stub)
        plt.close(fig)
        return

    color_map = {
        "pos_assoc": "#1b7837",
        "neg_assoc": "#c51b7d",
        "moderates": "#fdb863",
        "mediates":  "#5e3c99",
        "causes":    "#b35806",
        "assoc":     "#888888",
    }
    
    rollup_map, applied, note = _build_level_map(constructs_df, level)
    if note:
        print("littext: " + note, flush=True)

    def _roll(name):
        return rollup_map.get(name, name) if (applied and rollup_map) else name

    rels = (
        relations_df
        .sort_values("confidence", ascending=False)
        .drop_duplicates(subset=["source", "target", "relation_type"])
        .head(top * 4)
    )

    # Aggregate edges by (rolled_source, rolled_target, relation_type).
   
    agg = {}
    for _, r in rels.iterrows():
        rs = _roll(r["source"])
        rt = _roll(r["target"])
        if rs == rt:
            continue
        key = (rs, rt, r["relation_type"])
        agg[key] = agg.get(key, 0.0) + float(r["confidence"])

    if not agg:
        fig, ax = plt.subplots(figsize=(8, 6))
        ax.text(0.5, 0.5, "Empty relationship graph.", ha="center", va="center", fontsize=12)
        ax.set_axis_off()
        _save_both(fig, out_stub)
        plt.close(fig)
        return

    # Node set and a simple layout graph (edge multiplicity irrelevant to
    # layout). Keep the top-degree nodes for legibility.
    from collections import Counter
    deg = Counter()
    for (rs, rt, _t) in agg:
        deg[rs] += 1
        deg[rt] += 1
    keep_nodes = set(n for n, _ in deg.most_common(max(top, 5)))
    agg = {k: v for k, v in agg.items() if k[0] in keep_nodes and k[1] in keep_nodes}

    g_layout = nx.DiGraph()
    g_layout.add_nodes_from(keep_nodes)
    for (rs, rt, _t) in agg:
        g_layout.add_edge(rs, rt)

    if g_layout.number_of_nodes() == 0:
        fig, ax = plt.subplots(figsize=(8, 6))
        ax.text(0.5, 0.5, "Empty relationship graph.", ha="center", va="center", fontsize=12)
        ax.set_axis_off()
        _save_both(fig, out_stub)
        plt.close(fig)
        return

    pos = nx.spring_layout(g_layout, seed=42, k=0.9)

    title_level = "" if not (applied and rollup_map) else " -- rolled to level({})".format(level)

    if _want_html(fmt):
        node_xy = {n: (float(pos[n][0]), float(pos[n][1])) for n in g_layout.nodes()}
        node_size = {n: 10 + 2 * deg.get(n, 1) for n in g_layout.nodes()}
        edges_by_type = {}
        for (rs, rt, rtype), w in agg.items():
            edges_by_type.setdefault(rtype, []).append((rs, rt, w))
        _plotly_network(node_xy, node_size, None, edges_by_type,
                        "Candidate construct-relationship network" + title_level,
                        out_stub, embed)

    if not _want_static(fmt):
        return

    fig, ax = plt.subplots(figsize=(11, 9))

    if weighted:
        # Edges coloured continuously by confidence (viridis). Parallel
        # edges of different types between a pair are fanned by curvature.
        import matplotlib.cm as cm
        from matplotlib.colors import Normalize
        weights = list(agg.values())
        wmin, wmax = min(weights), max(weights)
        norm = Normalize(vmin=wmin, vmax=wmax)
        cmap = cm.get_cmap("viridis")
        type_order = {t: i for i, t in enumerate(color_map)}
        for (rs, rt, rtype), w in agg.items():
            rad = 0.08 * (type_order.get(rtype, 0) - 2)
            nx.draw_networkx_edges(
                g_layout, pos, edgelist=[(rs, rt)], edge_color=[cmap(norm(w))],
                width=1.0 + 4.0 * (w - wmin) / (wmax - wmin + 1e-9), alpha=0.85,
                arrows=True, arrowsize=10, ax=ax,
                connectionstyle="arc3,rad={:.3f}".format(rad))
        sm = cm.ScalarMappable(norm=norm, cmap=cmap)
        sm.set_array([])
        cbar = fig.colorbar(sm, ax=ax, shrink=0.5, pad=0.02)
        cbar.set_label("Edge confidence (summed within type)")
        title_suffix = " (edges by confidence)"
    else:
        # Edges by relation-type color. Each type is drawn as its own layer,
        # fanned by a small per-type curvature, so parallel edges of
        # different types between a pair stay visually distinct.
        type_order = {t: i for i, t in enumerate(color_map)}
        for rtype, color in color_map.items():
            edges = [(rs, rt) for (rs, rt, t) in agg if t == rtype]
            if not edges:
                continue
            widths = [1.0 + 4.0 * min(agg[(rs, rt, rtype)], 1.0) for (rs, rt) in edges]
            rad = 0.08 * (type_order.get(rtype, 0) - 2)
            nx.draw_networkx_edges(g_layout, pos, edgelist=edges, edge_color=color,
                                   width=widths, alpha=0.7, arrows=True, arrowsize=10,
                                   ax=ax, connectionstyle="arc3,rad={:.3f}".format(rad))
        title_suffix = " (edges by relation type)"

    nx.draw_networkx_nodes(g_layout, pos, node_size=400, node_color="#dddddd",
                           edgecolors="#444444", linewidths=0.8, ax=ax)
    nx.draw_networkx_labels(g_layout, pos, font_size=9, ax=ax)

    if not weighted:
        from matplotlib.lines import Line2D
        legend_elements = [
            Line2D([0], [0], color=color_map[k], lw=2, label=k)
            for k in ["pos_assoc", "neg_assoc", "moderates", "mediates", "causes", "assoc"]
        ]
        ax.legend(handles=legend_elements, loc="lower right", fontsize=8, frameon=False)

    ax.set_title("Candidate construct-relationship network" + title_suffix + title_level)
    ax.set_axis_off()
    _save_both(fig, out_stub)
    plt.close(fig)


def _draw_dendrogram(constructs_df: pd.DataFrame, embeddings: np.ndarray, top: int,
                     out_stub: str, fmt: str = "static",
                     embed: str = "selfcontained") -> None:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from scipy.cluster.hierarchy import linkage, dendrogram
    from scipy.spatial.distance import pdist

    if len(constructs_df) < 3:
        fig, ax = plt.subplots(figsize=(8, 6))
        ax.text(0.5, 0.5, "Too few constructs for a dendrogram\n(need at least 3).",
                ha="center", va="center", fontsize=12)
        ax.set_axis_off()
        _save_both(fig, out_stub)
        plt.close(fig)
        return

    # Restrict to top-K constructs to keep the figure legible
    cf = constructs_df.copy().reset_index(drop=True)
    cf["__idx__"] = cf.index
    top_idx = cf.sort_values("freq_doc", ascending=False).head(max(top, 10))["__idx__"].tolist()
    sub_emb = embeddings[top_idx]
    sub_labels = cf.loc[top_idx, "canonical_form"].tolist()
    dist = pdist(sub_emb, metric="cosine")
    z = linkage(dist, method="average")

    if _want_html(fmt):
        _plotly_dendrogram(sub_emb, sub_labels,
                           "Construct-cluster dendrogram (cosine distance, average linkage)",
                           out_stub, embed)

    if not _want_static(fmt):
        return

    fig, ax = plt.subplots(figsize=(10, max(6, 0.25 * len(sub_labels))))
    dendrogram(z, labels=sub_labels, orientation="left", leaf_font_size=9, color_threshold=0.3 * z[:, 2].max(), ax=ax)
    ax.set_title("Construct-cluster dendrogram (cosine distance, average linkage)")
    ax.set_xlabel("Cosine distance")
    _save_both(fig, out_stub)
    plt.close(fig)


def _draw_cooccurrence(constructs_df: pd.DataFrame, relations_df: pd.DataFrame,
                       top: int, out_stub: str, fmt: str = "static",
                       embed: str = "selfcontained") -> None:
    """pairwise NPMI heatmap of top-k constructs.
    """
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import numpy as np

    if len(constructs_df) == 0 or len(relations_df) == 0:
        fig, ax = plt.subplots(figsize=(8, 6))
        ax.text(0.5, 0.5, "Not enough data for a co-occurrence heatmap.",
                ha="center", va="center", fontsize=12)
        ax.set_axis_off()
        _save_both(fig, out_stub)
        plt.close(fig)
        return

    # Aggregate to canonical-form level (constructs frame may have multiple
    # surface forms per canonical cluster).
    canon_freq = (
        constructs_df.groupby("canonical_form")["freq_doc"].sum()
        .sort_values(ascending=False)
    )
    top_constructs = canon_freq.head(top).index.tolist()
    n = len(top_constructs)
    if n < 2:
        fig, ax = plt.subplots(figsize=(8, 6))
        ax.text(0.5, 0.5, f"Only {n} canonical constructs - heatmap requires >=2.",
                ha="center", va="center", fontsize=12)
        ax.set_axis_off()
        _save_both(fig, out_stub)
        plt.close(fig)
        return

    # Build the matrix: max confidence between each pair (relations may
    # contain multiple rows per pair from different sentences; we take the
    # highest confidence as the cell value because the lower-confidence
    # rows are typically duplicates).
    idx = {c: i for i, c in enumerate(top_constructs)}
    M = np.full((n, n), np.nan)
    for _, r in relations_df.iterrows():
        s, t = r["source"], r["target"]
        if s in idx and t in idx:
            i, j = idx[s], idx[t]
            conf = float(r["confidence"])
            # Symmetric: cell (i,j) and (j,i) both get the max confidence
            if np.isnan(M[i, j]) or conf > M[i, j]:
                M[i, j] = conf
            if np.isnan(M[j, i]) or conf > M[j, i]:
                M[j, i] = conf
    # Mask the diagonal
    np.fill_diagonal(M, np.nan)

    if _want_html(fmt):
        # Plotly heatmap: replace NaN with None so gaps render as blank.
        zmat = [[None if (v != v) else float(v) for v in row] for row in M]
        _plotly_heatmap(zmat, top_constructs, top_constructs,
                        "Construct co-occurrence (top {} by document frequency)".format(n),
                        "Max pair confidence", out_stub, embed, colorscale="YlOrRd")

    if not _want_static(fmt):
        return

    # Plot
    fig_w = max(8, 0.4 * n + 4)
    fig_h = max(6, 0.4 * n + 3)
    fig, ax = plt.subplots(figsize=(fig_w, fig_h))
    cmap = plt.get_cmap("YlOrRd")
    cmap.set_bad(color="#f0f0f0")  # NaN cells in light grey
    im = ax.imshow(M, cmap=cmap, vmin=0.0, vmax=1.0, aspect="auto")
    ax.set_xticks(range(n))
    ax.set_yticks(range(n))
    ax.set_xticklabels(top_constructs, rotation=45, ha="right", fontsize=8)
    ax.set_yticklabels(top_constructs, fontsize=8)
    ax.set_title(f"Construct co-occurrence (top {n} by document frequency)")
    cbar = fig.colorbar(im, ax=ax, shrink=0.7)
    cbar.set_label("Maximum pair confidence")
    plt.tight_layout()
    _save_both(fig, out_stub)
    plt.close(fig)


def _draw_roles(constructs_df: pd.DataFrame, relations_df: pd.DataFrame,
                top: int, out_stub: str, fmt: str = "static",
                embed: str = "selfcontained") -> None:
    """construct x relation-type heatmap.
    """
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import numpy as np

    if len(constructs_df) == 0 or len(relations_df) == 0:
        fig, ax = plt.subplots(figsize=(8, 6))
        ax.text(0.5, 0.5, "Not enough data for a roles heatmap.",
                ha="center", va="center", fontsize=12)
        ax.set_axis_off()
        _save_both(fig, out_stub)
        plt.close(fig)
        return

    canon_freq = (
        constructs_df.groupby("canonical_form")["freq_doc"].sum()
        .sort_values(ascending=False)
    )
    top_constructs = canon_freq.head(top).index.tolist()
    n = len(top_constructs)
    if n < 1:
        fig, ax = plt.subplots(figsize=(8, 6))
        ax.text(0.5, 0.5, "No canonical constructs.",
                ha="center", va="center", fontsize=12)
        ax.set_axis_off()
        _save_both(fig, out_stub)
        plt.close(fig)
        return

    rel_types = ["pos_assoc", "neg_assoc", "moderates", "mediates", "causes", "assoc"]
    idx = {c: i for i, c in enumerate(top_constructs)}
    M = np.zeros((n, len(rel_types)), dtype=int)
    for _, r in relations_df.iterrows():
        rt = r["relation_type"]
        if rt not in rel_types:
            continue
        col = rel_types.index(rt)
        for endpoint in (r["source"], r["target"]):
            if endpoint in idx:
                M[idx[endpoint], col] += 1

    if _want_html(fmt):
        zmat = [[int(M[i, j]) for j in range(len(rel_types))] for i in range(n)]
        txt = [[str(M[i, j]) if M[i, j] > 0 else "" for j in range(len(rel_types))]
               for i in range(n)]
        _plotly_heatmap(zmat, rel_types, top_constructs,
                        "Construct roles by relation type (top {})".format(n),
                        "Participation count", out_stub, embed,
                        colorscale="Blues", text_vals=txt)

    if not _want_static(fmt):
        return

    fig_w = max(7, 1.0 * len(rel_types) + 4)
    fig_h = max(6, 0.35 * n + 3)
    fig, ax = plt.subplots(figsize=(fig_w, fig_h))
    cmap = plt.get_cmap("Blues")
    im = ax.imshow(M, cmap=cmap, aspect="auto")
    ax.set_xticks(range(len(rel_types)))
    ax.set_yticks(range(n))
    ax.set_xticklabels(rel_types, rotation=30, ha="right", fontsize=9)
    ax.set_yticklabels(top_constructs, fontsize=8)
    ax.set_title(f"Construct roles by relation type (top {n})")
    # Annotate cells with their counts (only non-zero)
    for i in range(n):
        for j in range(len(rel_types)):
            v = M[i, j]
            if v > 0:
                # White text on dark cells, black text on light cells
                threshold = M.max() * 0.5
                color = "white" if v > threshold else "black"
                ax.text(j, i, str(v), ha="center", va="center",
                        fontsize=8, color=color)
    cbar = fig.colorbar(im, ax=ax, shrink=0.7)
    cbar.set_label("Participation count")
    plt.tight_layout()
    _save_both(fig, out_stub)
    plt.close(fig)


# ======================================================================
# Plotly interactive (HTML) builders. 
# Plotly is imported lazily so -littext analyze- and static-only figures
# never pay the import cost.
# ======================================================================

_REL_COLORS = {
    "pos_assoc": "#1b7837",
    "neg_assoc": "#c51b7d",
    "moderates": "#fdb863",
    "mediates":  "#5e3c99",
    "causes":    "#b35806",
    "assoc":     "#888888",
}


def _plotly_network(node_xy, node_size, node_label, edges_by_type, title,
                    out_stub, embed):
    """edges_by_type: dict relation_type -> list of (src_label, tgt_label, weight).
    node_xy: dict label -> (x, y). Interactive hover shows node label and
    edge type/weight."""
    import plotly.graph_objects as go

    traces = []
    for rtype, edges in edges_by_type.items():
        if not edges:
            continue
        ex, ey, hover = [], [], []
        for s, t, w in edges:
            if s not in node_xy or t not in node_xy:
                continue
            x0, y0 = node_xy[s]
            x1, y1 = node_xy[t]
            ex += [x0, x1, None]
            ey += [y0, y1, None]
            hover.append("{} -[{}]-> {}  (w={:.2f})".format(s, rtype, t, w))
        if not ex:
            continue
        traces.append(go.Scatter(
            x=ex, y=ey, mode="lines",
            line=dict(width=1.5, color=_REL_COLORS.get(rtype, "#888888")),
            name=rtype, hoverinfo="name", opacity=0.7))

    nx_, ny_, ntext, nsize = [], [], [], []
    for lab, (x, y) in node_xy.items():
        nx_.append(x)
        ny_.append(y)
        ntext.append(lab)
        nsize.append(node_size.get(lab, 10))
    traces.append(go.Scatter(
        x=nx_, y=ny_, mode="markers+text", text=ntext,
        textposition="top center", hoverinfo="text",
        marker=dict(size=nsize, color="#cccccc", line=dict(width=1, color="#444")),
        name="constructs", showlegend=False))

    fig = go.Figure(data=traces)
    fig.update_layout(title=title, showlegend=True, hovermode="closest",
                      xaxis=dict(visible=False), yaxis=dict(visible=False),
                      plot_bgcolor="white")
    _save_html(fig, out_stub, embed)
    _html_note(out_stub)


def _plotly_scatter(xs, ys, labels, sizes, groups, title, out_stub, embed):
    """Concept map: hover shows the construct label. groups colours points."""
    import plotly.graph_objects as go
    import pandas as _pd

    df = _pd.DataFrame({"x": xs, "y": ys, "label": labels, "size": sizes,
                        "group": groups})
    fig = go.Figure()
    for g, sub in df.groupby("group"):
        fig.add_trace(go.Scatter(
            x=sub["x"], y=sub["y"], mode="markers", text=sub["label"],
            hoverinfo="text",
            marker=dict(size=(8 + sub["size"].clip(upper=20)).tolist()),
            name=str(g), showlegend=False))
    fig.update_layout(title=title, hovermode="closest",
                      xaxis_title="UMAP-1", yaxis_title="UMAP-2",
                      plot_bgcolor="white")
    _save_html(fig, out_stub, embed)
    _html_note(out_stub)


def _plotly_heatmap(matrix, x_labels, y_labels, title, colorbar_title,
                    out_stub, embed, colorscale="YlOrRd", text_vals=None):
    import plotly.graph_objects as go

    fig = go.Figure(data=go.Heatmap(
        z=matrix, x=x_labels, y=y_labels, colorscale=colorscale,
        colorbar=dict(title=colorbar_title),
        text=text_vals, hoverongaps=False))
    fig.update_layout(title=title, plot_bgcolor="white",
                      xaxis=dict(tickangle=-45))
    _save_html(fig, out_stub, embed)
    _html_note(out_stub)


def _plotly_dendrogram(sub_emb, sub_labels, title, out_stub, embed):
    import plotly.figure_factory as ff
    from scipy.spatial.distance import pdist

    def _dist(x):
        return pdist(x, metric="cosine")

    fig = ff.create_dendrogram(sub_emb, labels=sub_labels, orientation="left",
                               distfun=_dist, linkagefun=lambda d: __import__(
                                   "scipy.cluster.hierarchy",
                                   fromlist=["linkage"]).linkage(d, method="average"))
    fig.update_layout(title=title, plot_bgcolor="white")
    _save_html(fig, out_stub, embed)
    _html_note(out_stub)
