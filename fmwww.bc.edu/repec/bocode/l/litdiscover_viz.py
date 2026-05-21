"""litdiscover_viz.py  v0.2.8  14may2026

Block A.5 visualisation helper for litdiscover.

This script is invoked from the litdiscover Stata command (.ado) via
`python script "litdiscover_viz.py"` after the Block A pipeline has
written its .dta outputs and the pyLDAvis interchange file. It
produces:

  * Python-tier static figures (when figures flag is set):
      - litdiscover_fig_coherence.png         (per-topic UMass bars)
      - litdiscover_fig_topicterms.png        (top-10 terms per topic)
      - litdiscover_fig_wordcloud_t<k>.png    (one wordcloud per topic)

  * Interactive HTML deliverables (when interactive flag is set):
      - litdiscover_topicvis.html             (pyLDAvis)
      - litdiscover_network.html              (pyvis cooc network)
      - litdiscover_sankey.html               (plotly theory->topic)

Inputs are read from Stata locals via the SFI Macro interface. Outputs
are written to the figures and interactive directories. Two manifest
files (_viz_manifest_figures.txt and _viz_manifest_interactive.txt) are
written so the .ado can enumerate produced files.

Dependencies: pandas, numpy, matplotlib, seaborn, pyLDAvis, pyvis,
plotly, networkx, wordcloud.
"""

import os
import sys
import warnings

# Force joblib (used by scikit-learn internally, via pyLDAvis's MDS call)
# to run sequentially. On Windows, joblib's default loky backend spawns
# worker subprocesses that briefly open console windows and occasionally
# emit a "resource_tracker: process died" UserWarning. Both issues are
# cosmetic but visually disruptive in Stata's Results window. For the
# small tasks litdiscover_viz runs (MDS on at most a handful of topics),
# sequential execution is also faster than spawning workers.
os.environ["LOKY_MAX_CPU_COUNT"] = "1"
os.environ["JOBLIB_MULTIPROCESSING"] = "0"

from sfi import Macro

# ---------------------------------------------------------------------
# Suppress noisy scikit-learn warnings that pyLDAvis triggers internally
# when calling sklearn's MDS for topic-distance computation. These are
# advisory only and do not affect output correctness; suppressing them
# keeps Stata's Results window clean during interactive-tier rendering.
# ---------------------------------------------------------------------
warnings.filterwarnings("ignore", category=FutureWarning, module="sklearn")
warnings.filterwarnings("ignore", category=DeprecationWarning, module="sklearn")
warnings.filterwarnings("ignore", category=UserWarning, module="joblib")

# ---------------------------------------------------------------------
# Read Stata locals
# ---------------------------------------------------------------------
def _local(name, default=""):
    v = Macro.getLocal(name)
    return v if v is not None else default

do_figures     = (_local("viz_do_figures") == "1")
do_interactive = (_local("viz_do_interactive") == "1")
tabledir       = _local("viz_tabledir")
figdir         = _local("viz_figdir")
intdir         = _local("viz_intdir")
sankeytopfreq  = int(_local("viz_sankeytopfreq", "15"))
pyldavis_path  = _local("viz_pyldavispath")

# ---------------------------------------------------------------------
# Dependency check
# ---------------------------------------------------------------------
_missing = []
try:
    import pandas as pd
except ImportError:
    _missing.append("pandas")
try:
    import numpy as np
except ImportError:
    _missing.append("numpy")

if do_figures or do_interactive:
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        _missing.append("matplotlib")
    try:
        import seaborn as sns
    except ImportError:
        _missing.append("seaborn")

if do_figures:
    try:
        from wordcloud import WordCloud
    except ImportError:
        _missing.append("wordcloud")

if do_interactive:
    try:
        import pyLDAvis
    except ImportError:
        _missing.append("pyLDAvis")
    try:
        from pyvis.network import Network
    except ImportError:
        _missing.append("pyvis")
    try:
        import plotly.graph_objects as go
    except ImportError:
        _missing.append("plotly")
    try:
        import networkx as nx
    except ImportError:
        _missing.append("networkx")

if _missing:
    sys.stderr.write(
        "\nlitdiscover_viz.py: missing Python package(s): "
        + ", ".join(_missing) + "\n"
    )
    sys.stderr.write(
        "Install with:  pip install " + " ".join(_missing) + "\n\n"
    )
    raise SystemExit(199)

# ---------------------------------------------------------------------
# Manifest accumulators
# ---------------------------------------------------------------------
figure_files = []
interactive_files = []

# ---------------------------------------------------------------------
# Style defaults
# ---------------------------------------------------------------------
sns.set_theme(style="whitegrid", context="paper")
DPI = 300
FIG_W = 7.5
FIG_H = 5.5

# ---------------------------------------------------------------------
# FIGURES: Python-tier
# ---------------------------------------------------------------------
if do_figures:

    # -----------------------------------------------------------------
    # Fig 6: per-topic UMass coherence bar chart
    # Gated on availability of litdiscover_coherence.dta
    # -----------------------------------------------------------------
    coh_dta = os.path.join(tabledir, "litdiscover_coherence.dta")
    if os.path.isfile(coh_dta):
        try:
            coh = pd.read_stata(coh_dta)
            if len(coh) > 0 and "umass" in coh.columns and "topic" in coh.columns:
                fig, ax = plt.subplots(figsize=(FIG_W, FIG_H), dpi=DPI)
                coh_sorted = coh.sort_values("topic")
                ax.barh(
                    coh_sorted["topic"].astype(str),
                    coh_sorted["umass"],
                    color="#0072B2",
                )
                ax.set_xlabel("UMass coherence (closer to zero = more coherent)")
                ax.set_ylabel("Topic")
                ax.set_title("Per-topic UMass coherence")
                ax.invert_yaxis()
                plt.tight_layout()
                out = os.path.join(figdir, "litdiscover_fig_coherence.png")
                fig.savefig(out, dpi=DPI, bbox_inches="tight")
                plt.close(fig)
                figure_files.append("litdiscover_fig_coherence.png")
        except Exception as exc:
            sys.stderr.write(
                "litdiscover_viz.py: coherence figure skipped: "
                + repr(exc) + "\n"
            )

    # -----------------------------------------------------------------
    # Fig 7: top-10 terms per topic, small multiples
    # -----------------------------------------------------------------
    tt_dta = os.path.join(tabledir, "litdiscover_topicterms.dta")
    if os.path.isfile(tt_dta):
        try:
            tt = pd.read_stata(tt_dta)
            if len(tt) > 0:
                topics = sorted(tt["topic"].unique())
                K = len(topics)
                ncols = min(3, K)
                nrows = int(np.ceil(K / ncols))
                fig, axes = plt.subplots(
                    nrows, ncols,
                    figsize=(FIG_W * 1.2, FIG_H * 0.7 * nrows),
                    dpi=DPI,
                    squeeze=False,
                )
                for i, t in enumerate(topics):
                    r, c = divmod(i, ncols)
                    ax = axes[r][c]
                    sub = (
                        tt[tt["topic"] == t]
                        .sort_values("rank")
                        .head(10)
                    )
                    ax.barh(
                        sub["term"][::-1],
                        sub["weight"][::-1],
                        color="#0072B2",
                    )
                    ax.set_title("Topic " + str(int(t)), fontsize=10)
                    ax.tick_params(axis="y", labelsize=8)
                    ax.tick_params(axis="x", labelsize=8)
                # blank unused panels
                for j in range(K, nrows * ncols):
                    r, c = divmod(j, ncols)
                    axes[r][c].set_visible(False)
                fig.suptitle("Top 10 terms per topic", fontsize=12)
                plt.tight_layout(rect=(0, 0, 1, 0.96))
                out = os.path.join(figdir, "litdiscover_fig_topicterms.png")
                fig.savefig(out, dpi=DPI, bbox_inches="tight")
                plt.close(fig)
                figure_files.append("litdiscover_fig_topicterms.png")
        except Exception as exc:
            sys.stderr.write(
                "litdiscover_viz.py: topicterms figure skipped: "
                + repr(exc) + "\n"
            )

    # -----------------------------------------------------------------
    # Fig 8: per-topic wordclouds
    # -----------------------------------------------------------------
    if os.path.isfile(tt_dta):
        try:
            tt = pd.read_stata(tt_dta)
            if len(tt) > 0:
                for t in sorted(tt["topic"].unique()):
                    sub = tt[tt["topic"] == t]
                    freqs = {
                        str(row["term"]): float(row["weight"])
                        for _, row in sub.iterrows()
                        if float(row["weight"]) > 0
                    }
                    if not freqs:
                        continue
                    wc = WordCloud(
                        width=1600,
                        height=1000,
                        background_color="white",
                        colormap="viridis",
                        prefer_horizontal=0.9,
                    ).generate_from_frequencies(freqs)
                    fig, ax = plt.subplots(figsize=(FIG_W, FIG_H), dpi=DPI)
                    ax.imshow(wc, interpolation="bilinear")
                    ax.set_axis_off()
                    ax.set_title("Topic " + str(int(t)))
                    plt.tight_layout()
                    fname = "litdiscover_fig_wordcloud_t" + str(int(t)) + ".png"
                    out = os.path.join(figdir, fname)
                    fig.savefig(out, dpi=DPI, bbox_inches="tight")
                    plt.close(fig)
                    figure_files.append(fname)
        except Exception as exc:
            sys.stderr.write(
                "litdiscover_viz.py: wordcloud figures skipped: "
                + repr(exc) + "\n"
            )

# ---------------------------------------------------------------------
# INTERACTIVE: pyLDAvis, pyvis, plotly Sankey
# ---------------------------------------------------------------------
if do_interactive:

    # -----------------------------------------------------------------
    # litdiscover_topicvis.html via pyLDAvis
    #
    # Load the interchange file written by litdiscover.py, which
    # contains the five arrays required by pyLDAvis.prepare(). No LDA
    # re-fit; the visualisation is mathematically derived from the
    # same primary-seed model that produced litdiscover_doctopic.dta
    # and litdiscover_topicterms.dta.
    # -----------------------------------------------------------------
    if pyldavis_path and os.path.isfile(pyldavis_path):
        try:
            with open(pyldavis_path, "rb") as _fh:
                _data = np.load(_fh, allow_pickle=False)
                topic_term_dists = _data["topic_term_dists"]
                doc_topic_dists  = _data["doc_topic_dists"]
                doc_lengths      = _data["doc_lengths"]
                vocab_arr        = _data["vocab"]
                term_frequency   = _data["term_frequency"]
            panel = pyLDAvis.prepare(
                topic_term_dists=topic_term_dists,
                doc_topic_dists=doc_topic_dists,
                doc_lengths=doc_lengths,
                vocab=list(vocab_arr),
                term_frequency=term_frequency,
            )
            out = os.path.join(intdir, "litdiscover_topicvis.html")
            pyLDAvis.save_html(panel, out)
            interactive_files.append("litdiscover_topicvis.html")
        except Exception as exc:
            sys.stderr.write(
                "litdiscover_viz.py: pyLDAvis skipped: "
                + repr(exc) + "\n"
            )
    else:
        sys.stderr.write(
            "litdiscover_viz.py: pyLDAvis skipped: "
            "interchange file not found at " + str(pyldavis_path) + "\n"
        )

    # -----------------------------------------------------------------
    # litdiscover_network.html via pyvis
    # Within-field cooc only; edges weighted by Jaccard >= 0.1.
    # Nodes coloured by field, sized by paper count from construct_freq.
    # -----------------------------------------------------------------
    cw_dta = os.path.join(tabledir, "litdiscover_cooc_within.dta")
    cf_dta = os.path.join(tabledir, "litdiscover_construct_freq.dta")
    if os.path.isfile(cw_dta) and os.path.isfile(cf_dta):
        try:
            cw = pd.read_stata(cw_dta)
            cf = pd.read_stata(cf_dta)
            cw = cw.dropna(subset=["jaccard"])
            cw = cw[cw["jaccard"] >= 0.1]
            if len(cw) > 0:
                # palette for fields
                field_palette = {
                    "theory":   "#1f77b4",
                    "dv":       "#d62728",
                    "iv":       "#2ca02c",
                    "mod":      "#9467bd",
                    "med":      "#8c564b",
                    "decision": "#e377c2",
                    "context":  "#ff7f0e",
                    "method":   "#17becf",
                    "journal":  "#7f7f7f",
                }
                # node table: unique (field, value) with paper count
                node_lookup = {
                    (str(r["field"]), str(r["value"])): float(r["n_docs"])
                    for _, r in cf.iterrows()
                }
                # node sizing: log scale to keep visualisation readable
                def _size(npapers):
                    return float(10.0 + 6.0 * np.log1p(max(0.0, npapers)))
                # Network() signature varies across pyvis versions; try the
                # modern call first (cdn_resources='in_line' produces a
                # fully self-contained HTML), fall back if unsupported.
                try:
                    net = Network(
                        height="800px",
                        width="100%",
                        bgcolor="#ffffff",
                        font_color="#222222",
                        notebook=False,
                        cdn_resources="in_line",
                    )
                except TypeError:
                    net = Network(
                        height="800px",
                        width="100%",
                        bgcolor="#ffffff",
                        font_color="#222222",
                        notebook=False,
                    )
                added_nodes = set()
                for _, row in cw.iterrows():
                    f = str(row["field"])
                    va = str(row["value_a"])
                    vb = str(row["value_b"])
                    for v in (va, vb):
                        key = (f, v)
                        if key in added_nodes:
                            continue
                        npapers = node_lookup.get(key, 0.0)
                        col = field_palette.get(f, "#444444")
                        tip = (
                            "Field: " + f
                            + "<br>Value: " + v
                            + "<br>Documents: " + str(int(npapers))
                        )
                        net.add_node(
                            f + "::" + v,
                            label=v,
                            color=col,
                            size=_size(npapers),
                            title=tip,
                            group=f,
                        )
                        added_nodes.add(key)
                    weight = float(row["jaccard"])
                    tip_e = (
                        "Field: " + f
                        + "<br>" + va + " <-> " + vb
                        + "<br>n_both: " + str(int(row.get("n_both", 0)))
                        + "<br>Jaccard: " + ("%.3f" % weight)
                    )
                    net.add_edge(
                        f + "::" + va,
                        f + "::" + vb,
                        value=weight,
                        title=tip_e,
                    )
                net.toggle_physics(True)
                out = os.path.join(intdir, "litdiscover_network.html")
                # pyvis.network.write_html() has a known bug on Windows:
                # it calls open(name, "w+") without specifying encoding,
                # so the file is opened with the cp1252 codec, which
                # cannot represent some Unicode characters in the HTML
                # template. To avoid this, we always generate the HTML
                # in memory and write it ourselves with explicit UTF-8.
                # Reference: pyvis upstream issue (run-llama/llama_index#448).
                try:
                    html_content = net.generate_html(notebook=False)
                except TypeError:
                    html_content = net.generate_html()
                with open(out, "w", encoding="utf-8") as fh:
                    fh.write(html_content)
                interactive_files.append("litdiscover_network.html")
        except Exception as exc:
            sys.stderr.write(
                "litdiscover_viz.py: pyvis network skipped: "
                + repr(exc) + "\n"
            )

    # -----------------------------------------------------------------
    # litdiscover_sankey.html via plotly: theory -> topic
    # Source: topic_by_field.dta filtered to field == "theory".
    # Link width = n_docs. Topic labels include top-3 terms.
    # Theory nodes truncated to top sankeytopfreq by total n_docs.
    # -----------------------------------------------------------------
    tbf_dta = os.path.join(tabledir, "litdiscover_topic_by_field.dta")
    tt_dta  = os.path.join(tabledir, "litdiscover_topicterms.dta")
    if os.path.isfile(tbf_dta) and os.path.isfile(tt_dta):
        try:
            tbf = pd.read_stata(tbf_dta)
            tt  = pd.read_stata(tt_dta)
            tbf_theory = tbf[tbf["field"] == "theory"].copy()
            if len(tbf_theory) > 0:
                # truncate theories to top sankeytopfreq by total n_docs
                theory_totals = (
                    tbf_theory.groupby("value")["n_docs"].sum().reset_index()
                )
                theory_totals = theory_totals.sort_values(
                    "n_docs", ascending=False
                ).head(sankeytopfreq)
                keep_theories = set(theory_totals["value"].astype(str))
                tbf_theory = tbf_theory[
                    tbf_theory["value"].astype(str).isin(keep_theories)
                ]
                # topic labels: top-3 terms
                topic_labels = {}
                for t in sorted(tt["topic"].unique()):
                    top3 = (
                        tt[tt["topic"] == t]
                        .sort_values("rank")
                        .head(3)["term"]
                        .astype(str)
                        .tolist()
                    )
                    topic_labels[int(t)] = (
                        "T" + str(int(t)) + ": " + " - ".join(top3)
                    )
                # build node list (theories first, then topics)
                theories = sorted(tbf_theory["value"].astype(str).unique())
                topics = sorted(tbf_theory["topic"].astype(int).unique())
                nodes = list(theories) + [topic_labels[t] for t in topics]
                idx_theory = {th: i for i, th in enumerate(theories)}
                idx_topic = {
                    int(t): len(theories) + j for j, t in enumerate(topics)
                }
                sources = []
                targets = []
                values  = []
                for _, row in tbf_theory.iterrows():
                    th = str(row["value"])
                    tp = int(row["topic"])
                    n = float(row["n_docs"])
                    if n <= 0:
                        continue
                    sources.append(idx_theory[th])
                    targets.append(idx_topic[tp])
                    values.append(n)
                if values:
                    fig = go.Figure(go.Sankey(
                        node=dict(
                            pad=12,
                            thickness=14,
                            line=dict(color="black", width=0.4),
                            label=nodes,
                        ),
                        link=dict(
                            source=sources,
                            target=targets,
                            value=values,
                        ),
                    ))
                    fig.update_layout(
                        title_text=(
                            "Theory to topic flow"
                            " (link width = number of documents)"
                        ),
                        font_size=11,
                    )
                    out = os.path.join(intdir, "litdiscover_sankey.html")
                    fig.write_html(out, include_plotlyjs="inline")
                    interactive_files.append("litdiscover_sankey.html")
        except Exception as exc:
            sys.stderr.write(
                "litdiscover_viz.py: plotly Sankey skipped: "
                + repr(exc) + "\n"
            )

# ---------------------------------------------------------------------
# Write manifests
# ---------------------------------------------------------------------
if figure_files:
    try:
        with open(
            os.path.join(figdir, "_viz_manifest_figures.txt"),
            "w",
            encoding="utf-8",
        ) as fh:
            fh.write("\n".join(figure_files) + "\n")
    except Exception as exc:
        sys.stderr.write(
            "litdiscover_viz.py: failed to write figure manifest: "
            + repr(exc) + "\n"
        )

if interactive_files:
    try:
        with open(
            os.path.join(intdir, "_viz_manifest_interactive.txt"),
            "w",
            encoding="utf-8",
        ) as fh:
            fh.write("\n".join(interactive_files) + "\n")
    except Exception as exc:
        sys.stderr.write(
            "litdiscover_viz.py: failed to write interactive manifest: "
            + repr(exc) + "\n"
        )
