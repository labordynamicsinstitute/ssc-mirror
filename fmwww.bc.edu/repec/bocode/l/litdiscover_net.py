"""litdiscover_net.py  v0.3.0  14may2026

Copyright (C) 2026  Nebojsa S. Davcik, EM Normandie Business School.
Email: davcik@live.com.  ORCID: 0000-0003-1041-8788.
Repository: https://github.com/Davcik/litdiscover

Licensed under the GNU General Public License version 3 or later
(GPL-3.0-or-later). This program is distributed in the hope that it
will be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the LICENSE file in the repository root, or
<https://www.gnu.org/licenses/>, for details.

Block C (v0.3): network-analytic measures over the v0.2 construct
co-occurrence tables.

Reads two Stata datasets (paths supplied via Stata locals):

  - withindta   litdiscover_cooc_within.dta
                columns: field, value_a, value_b, n_both, n_a, n_b, jaccard
  - crossdta    litdiscover_cooc_cross.dta
                columns: field_a, value_a, field_b, value_b, n_both, n_a,
                         n_b, jaccard

Writes two CSV files (paths supplied via Stata locals):

  - withincsv   one row per (field, value); within-field networks
  - crosscsv    one row per (field_a, field_b, field, value); bipartite

The driving .ado imports each CSV via `import delimited` and saves as
.dta with the v0.2 file-naming convention (litdiscover_*).

Algorithm follows the v0.3 locked spec, sections A6 through A11.

Constants (hard-coded in v0.3; exposure deferred to v0.4):
  Louvain seed       = 20250101
  Louvain resolution = 1.0
  Edge attribute 'sim'  = jaccard           (Louvain and strength)
  Edge attribute 'dist' = 1 - jaccard       (betweenness; distance form)

Surfaces summary scalars back to Stata via Macro.setLocal so that the
.ado can return them as r() scalars without writing extra files:

  net_networks_within, net_networks_cross,
  net_nodes_within,    net_nodes_cross,
  net_modularity_mean, net_modularity_min, net_modularity_max,
  net_louvain_seed.
"""

import os
os.environ["LOKY_MAX_CPU_COUNT"] = "1"
os.environ["JOBLIB_MULTIPROCESSING"] = "0"

import warnings
warnings.filterwarnings("ignore", category=FutureWarning, module="sklearn")
warnings.filterwarnings("ignore", category=DeprecationWarning, module="sklearn")
warnings.filterwarnings("ignore", category=UserWarning, module="joblib")

from sfi import Macro
import math
import numpy as np
import pandas as pd
import networkx as nx
from networkx.algorithms import community as nx_community

LOUVAIN_SEED = 20250101
LOUVAIN_RESOLUTION = 1.0


def _read_stata_safe(path):
    """Read a .dta, returning an empty DataFrame on read failure."""
    try:
        return pd.read_stata(path, convert_categoricals=False)
    except (FileNotFoundError, ValueError) as exc:
        print("LITDISCOVER_NET: could not read", path, "-", str(exc))
        return pd.DataFrame()


def _build_graph(edge_rows, node_id_fn):
    """Build an undirected weighted graph from an iterable of edge rows.

    edge_rows: iterable of dicts with keys 'u', 'v', 'jaccard'.
    node_id_fn: identity function for simple graphs; namespacing for cross.
    """
    G = nx.Graph()
    for r in edge_rows:
        j = r["jaccard"]
        if j is None:
            continue
        if isinstance(j, float) and math.isnan(j):
            continue
        if j <= 0.0:
            continue
        u = node_id_fn(r["u"])
        v = node_id_fn(r["v"])
        if u == v:
            continue
        G.add_edge(u, v, sim=float(j), dist=float(1.0 - j))
    return G


def _measures_for_graph(G):
    """Return per-node measure dict and network-level scalars."""
    if G.number_of_nodes() == 0:
        return {}, 0, 0, float("nan"), []

    deg_norm = nx.degree_centrality(G)
    strength = dict(G.degree(weight="sim"))
    btw = nx.betweenness_centrality(G, weight="dist", normalized=True)

    try:
        communities = nx_community.louvain_communities(
            G,
            weight="sim",
            resolution=LOUVAIN_RESOLUTION,
            seed=LOUVAIN_SEED,
        )
    except Exception as exc:
        print("LITDISCOVER_NET: Louvain failed -", str(exc), "; falling back to singletons")
        communities = [{n} for n in G.nodes()]

    node_to_comm = {}
    for c_idx, members in enumerate(communities):
        for n in members:
            node_to_comm[n] = c_idx

    try:
        mod_val = nx_community.modularity(G, communities, weight="sim")
    except Exception as exc:
        print("LITDISCOVER_NET: modularity failed -", str(exc), "; setting NaN")
        mod_val = float("nan")

    per_node = {}
    for n in G.nodes():
        per_node[n] = {
            "degree":      float(deg_norm.get(n, 0.0)),
            "strength":    float(strength.get(n, 0.0)),
            "betweenness": float(btw.get(n, 0.0)),
            "community":   int(node_to_comm.get(n, 0)),
        }

    return (
        per_node,
        int(G.number_of_nodes()),
        int(G.number_of_edges()),
        float(mod_val),
        communities,
    )


def process_within(within_df):
    """Build one within-field network per distinct value of 'field'."""
    out_rows = []
    network_count = 0
    mods = []

    if within_df.empty:
        return pd.DataFrame(columns=[
            "field", "value", "n_nodes", "n_edges",
            "degree", "strength", "betweenness", "community", "modularity",
        ]), network_count, mods

    for field_val, sub in within_df.groupby("field", sort=True):
        edges = []
        for _, row in sub.iterrows():
            edges.append({
                "u": row["value_a"],
                "v": row["value_b"],
                "jaccard": row["jaccard"],
            })
        G = _build_graph(edges, node_id_fn=lambda x: x)
        if G.number_of_nodes() == 0:
            continue
        per_node, n_nodes, n_edges, mod_val, _ = _measures_for_graph(G)
        network_count += 1
        if not (isinstance(mod_val, float) and math.isnan(mod_val)):
            mods.append(mod_val)
        for n, m in per_node.items():
            out_rows.append({
                "field":       str(field_val),
                "value":       str(n),
                "n_nodes":     n_nodes,
                "n_edges":     n_edges,
                "degree":      m["degree"],
                "strength":    m["strength"],
                "betweenness": m["betweenness"],
                "community":   m["community"],
                "modularity":  mod_val,
            })

    out_df = pd.DataFrame(out_rows, columns=[
        "field", "value", "n_nodes", "n_edges",
        "degree", "strength", "betweenness", "community", "modularity",
    ])
    out_df.sort_values(["field", "value"], kind="mergesort", inplace=True)
    return out_df, network_count, mods


def process_cross(cross_df):
    """Build one bipartite network per unordered (field_a, field_b) pair."""
    cols_out = [
        "field_a", "field_b", "field", "value",
        "n_nodes", "n_edges",
        "degree", "strength", "betweenness", "community", "modularity",
    ]
    out_rows = []
    network_count = 0
    mods = []

    if cross_df.empty:
        return pd.DataFrame(columns=cols_out), network_count, mods

    grouped = cross_df.groupby(["field_a", "field_b"], sort=True)
    for (fa, fb), sub in grouped:
        edges = []
        for _, row in sub.iterrows():
            edges.append({
                "u": (str(fa), str(row["value_a"])),
                "v": (str(fb), str(row["value_b"])),
                "jaccard": row["jaccard"],
            })

        def ns(node_tuple):
            return node_tuple[0] + "::" + node_tuple[1]

        edges_ns = []
        for e in edges:
            j = e["jaccard"]
            if j is None:
                continue
            if isinstance(j, float) and math.isnan(j):
                continue
            if j <= 0.0:
                continue
            edges_ns.append({"u": ns(e["u"]), "v": ns(e["v"]), "jaccard": j})

        G = _build_graph(edges_ns, node_id_fn=lambda x: x)
        if G.number_of_nodes() == 0:
            continue
        per_node, n_nodes, n_edges, mod_val, _ = _measures_for_graph(G)
        network_count += 1
        if not (isinstance(mod_val, float) and math.isnan(mod_val)):
            mods.append(mod_val)
        for n, m in per_node.items():
            sep_idx = n.find("::")
            n_field = n[:sep_idx]
            n_value = n[sep_idx + 2:]
            out_rows.append({
                "field_a":     str(fa),
                "field_b":     str(fb),
                "field":       n_field,
                "value":       n_value,
                "n_nodes":     n_nodes,
                "n_edges":     n_edges,
                "degree":      m["degree"],
                "strength":    m["strength"],
                "betweenness": m["betweenness"],
                "community":   m["community"],
                "modularity":  mod_val,
            })

    out_df = pd.DataFrame(out_rows, columns=cols_out)
    out_df.sort_values(["field_a", "field_b", "field", "value"], kind="mergesort", inplace=True)
    return out_df, network_count, mods


def main():
    within_path = Macro.getLocal("withindta")
    cross_path  = Macro.getLocal("crossdta")
    within_csv  = Macro.getLocal("withincsv")
    cross_csv   = Macro.getLocal("crosscsv")

    print("LITDISCOVER_NET: reading", within_path)
    within_df = _read_stata_safe(within_path)
    print("LITDISCOVER_NET: reading", cross_path)
    cross_df = _read_stata_safe(cross_path)

    print("LITDISCOVER_NET: building within-field networks")
    within_out, n_within, mods_within = process_within(within_df)
    print("LITDISCOVER_NET: within networks =", n_within, ", rows =", len(within_out))

    print("LITDISCOVER_NET: building cross-field bipartite networks")
    cross_out, n_cross, mods_cross = process_cross(cross_df)
    print("LITDISCOVER_NET: cross networks =", n_cross, ", rows =", len(cross_out))

    with open(within_csv, "w", encoding="utf-8", newline="") as fh:
        within_out.to_csv(fh, index=False)
    print("LITDISCOVER_NET: wrote", within_csv)

    with open(cross_csv, "w", encoding="utf-8", newline="") as fh:
        cross_out.to_csv(fh, index=False)
    print("LITDISCOVER_NET: wrote", cross_csv)

    all_mods = mods_within  # spec: scalars summarise within networks only
    if len(all_mods) > 0:
        mod_mean = float(np.mean(all_mods))
        mod_min  = float(np.min(all_mods))
        mod_max  = float(np.max(all_mods))
    else:
        mod_mean = float("nan")
        mod_min  = float("nan")
        mod_max  = float("nan")

    Macro.setLocal("net_networks_within",  str(int(n_within)))
    Macro.setLocal("net_networks_cross",   str(int(n_cross)))
    Macro.setLocal("net_nodes_within",     str(int(len(within_out))))
    Macro.setLocal("net_nodes_cross",      str(int(len(cross_out))))
    Macro.setLocal("net_modularity_mean",  str(mod_mean))
    Macro.setLocal("net_modularity_min",   str(mod_min))
    Macro.setLocal("net_modularity_max",   str(mod_max))
    Macro.setLocal("net_louvain_seed",     str(int(LOUVAIN_SEED)))


main()
