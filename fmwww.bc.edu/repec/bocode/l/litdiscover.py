"""litdiscover.py  v1.0  15may2026

Copyright (C) 2026  Nebojsa S. Davcik, EM Normandie Business School.
Email: davcik@live.com.  ORCID: 0000-0003-1041-8788.
Repository: https://github.com/Davcik/litdiscover

Licensed under the GNU General Public License version 3 or later
(GPL-3.0-or-later). This program is distributed in the hope that it
will be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the LICENSE file in the repository root, or
<https://www.gnu.org/licenses/>, for details.

LDA engine for litdiscover. Reads a corpus CSV exported by the
litdiscover.ado driver and writes the following CSV outputs (paths
supplied as Stata locals):

  - corpuscsv      (input, read-only)
  - doccsv         document-topic table for the primary seed
  - keywordcsv     topic-term keywords for the primary seed
  - stabcsv        pairwise seed stability (only when seeds > 1)
  - cohcsv         UMass coherence per topic (only when do_coh=1)
  - modelcsv       single-row model metadata
"""

from sfi import Macro
import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.decomposition import LatentDirichletAllocation
from scipy.optimize import linear_sum_assignment
from scipy.stats import rankdata

input_path  = Macro.getLocal("corpuscsv")
doc_path    = Macro.getLocal("doccsv")
key_path    = Macro.getLocal("keywordcsv")
model_path  = Macro.getLocal("modelcsv")
stab_path   = Macro.getLocal("stabcsv")
coh_path    = Macro.getLocal("cohcsv")
n_topics    = int(Macro.getLocal("topics"))
seed_val    = int(Macro.getLocal("seed"))
minfreq_val = int(Macro.getLocal("minfreq"))
maxdf_val   = float(Macro.getLocal("maxdf"))
ngram_val   = int(Macro.getLocal("ngram"))
n_seeds     = int(Macro.getLocal("seeds"))
do_coh      = (Macro.getLocal("docoh") == "1")
# Block A.5 addition: empty string means "do not write the NPZ".
pyldavis_path = Macro.getLocal("pyldavispath")
# Block B (v0.3) addition: "1" means add a 'frex' column to keywordcsv.
# Any other value (including empty) means the keyword CSV is byte-identical
# to v0.2 (no 'frex' column at all).
do_frex     = (Macro.getLocal("dofrex") == "1")

print("LITDISCOVER: reading", input_path)
df = pd.read_csv(input_path)
df["abstract"] = df["abstract"].fillna("").astype(str).str.strip()
df = df[df["abstract"] != ""].copy()
print("LITDISCOVER: usable docs =", df.shape[0])

if df.shape[0] == 0:
    raise ValueError("No usable abstracts remain after cleaning.")

if maxdf_val >= 1.0:
    vectorizer = CountVectorizer(stop_words="english", min_df=minfreq_val, ngram_range=(1, ngram_val))
else:
    vectorizer = CountVectorizer(stop_words="english", min_df=minfreq_val, max_df=maxdf_val, ngram_range=(1, ngram_val))

X = vectorizer.fit_transform(df["abstract"])
print("LITDISCOVER: vocab size =", X.shape[1])

if X.shape[1] == 0:
    raise ValueError("Vocabulary is empty. Lower minfreq() or relax maxdf() or inspect abstracts.")

terms = vectorizer.get_feature_names_out()
topn = min(15, len(terms))


def fit_lda(seed_for_this_run):
    model = LatentDirichletAllocation(
        n_components=n_topics,
        random_state=seed_for_this_run,
        learning_method="batch"
    )
    doc_topic_local = model.fit_transform(X)
    return model, doc_topic_local


def top_term_sets(model):
    out = []
    for comp in model.components_:
        top_ids = comp.argsort()[::-1][:topn]
        out.append(set(terms[i] for i in top_ids))
    return out


def jaccard(a, b):
    if not a and not b:
        return 0.0
    return len(a & b) / len(a | b)


print("LITDISCOVER: fitting primary LDA (seed =", seed_val, ")")
primary_model, doc_topic = fit_lda(seed_val)
primary_term_sets = top_term_sets(primary_model)

# Document-topic and topic-keyword tables (primary run)
topic_cols = ["topic_" + str(i + 1) for i in range(n_topics)]
doc_out = pd.DataFrame(doc_topic, columns=topic_cols)
doc_out.insert(0, "study_id", df["study_id"].astype(str).values)
doc_out["dominant_topic"] = doc_topic.argmax(axis=1) + 1
doc_out["dominant_topic_share"] = doc_topic.max(axis=1)

key_rows = []
for topic_idx, comp in enumerate(primary_model.components_, start=1):
    top_ids = comp.argsort()[::-1][:topn]
    for rank, term_id in enumerate(top_ids, start=1):
        key_rows.append({
            "topic": topic_idx,
            "rank": rank,
            "term": terms[term_id],
            "weight": float(comp[term_id])
        })
key_out = pd.DataFrame(key_rows)

# ---------------------------------------------------------------------
# Block B: FREX (FRequency-EXclusivity) score
#
# Computed only when the Stata local dofrex == "1". When the toggle is
# off, the keyword CSV is byte-identical to v0.2 (no 'frex' column).
#
# Algorithm (Roberts, Stewart, and Tingley 2019):
#   beta_{k,v}  = row-normalised comp[k, v]  (topic-term probability)
#   f_{k,v}     = beta_{k,v}                 (frequency component)
#   e_{k,v}     = beta_{k,v} / (sum_{k'} beta_{k',v} + epsilon)
#   F_k(.), E_k(.) = empirical CDFs over the full vocabulary, per topic
#   FREX_{k,v}  = ( omega / E_k(e_{k,v}) + (1 - omega) / F_k(f_{k,v}) )^-1
# Constants: omega = 0.5 (stm default), epsilon = 1e-12.
# ECDF is computed via rankdata(..., method='average') / |V|.
# Edge case: |V| = 1 yields FREX = 1.0 for every topic.
# ---------------------------------------------------------------------
if do_frex:
    print("LITDISCOVER: computing FREX scores (Roberts et al. 2019)")
    frex_omega   = 0.5
    frex_epsilon = 1e-12

    comp_full = primary_model.components_.astype(np.float64)
    row_sums_full = comp_full.sum(axis=1, keepdims=True)
    row_sums_full[row_sums_full == 0] = 1.0
    beta_full = comp_full / row_sums_full

    V_size = beta_full.shape[1]

    if V_size <= 1:
        frex_full = np.ones_like(beta_full)
    else:
        col_sums = beta_full.sum(axis=0, keepdims=True)
        exclusivity = beta_full / (col_sums + frex_epsilon)
        frex_full = np.zeros_like(beta_full)
        for k_idx in range(beta_full.shape[0]):
            f_ecdf = rankdata(beta_full[k_idx, :], method="average") / V_size
            e_ecdf = rankdata(exclusivity[k_idx, :], method="average") / V_size
            denom = (frex_omega / e_ecdf) + ((1.0 - frex_omega) / f_ecdf)
            frex_full[k_idx, :] = 1.0 / denom

    term_to_id = {t: i for i, t in enumerate(terms)}
    frex_col = []
    for r in key_rows:
        k_idx = int(r["topic"]) - 1
        v_idx = term_to_id[r["term"]]
        frex_col.append(float(frex_full[k_idx, v_idx]))
    key_out["frex"] = frex_col
    print("LITDISCOVER: FREX omega =", frex_omega, ", epsilon =", frex_epsilon, ", |V| =", V_size)

    # Surface FREX metadata to the .ado via Stata locals (no file change,
    # so v0.2 byte-identity of model CSV is preserved when frex is off).
    Macro.setLocal("frex_omega",      str(frex_omega))
    Macro.setLocal("frex_epsilon",    str(frex_epsilon))
    Macro.setLocal("frex_topics",     str(int(n_topics)))
    Macro.setLocal("frex_vocab_size", str(int(V_size)))

doc_out.to_csv(doc_path, index=False)
key_out.to_csv(key_path, index=False)
print("LITDISCOVER: wrote", doc_path)
print("LITDISCOVER: wrote", key_path)

# Stability across seeds
if n_seeds > 1:
    print("LITDISCOVER: running stability over", n_seeds, "seeds")
    all_term_sets = [primary_term_sets]
    seeds_used = [seed_val]
    for k in range(1, n_seeds):
        s = seed_val + k
        _, _ = None, None
        m_k, _ = fit_lda(s)
        all_term_sets.append(top_term_sets(m_k))
        seeds_used.append(s)

    stab_rows = []
    n_runs = len(all_term_sets)
    pair_means = []
    # v0.3.1 addition: per-topic best-match Jaccard from the primary seed
    # (index 0 in all_term_sets) to each non-primary seed. Shape (K, S-1).
    primary_matches = np.zeros((n_topics, n_runs - 1), dtype=np.float64)

    for i in range(n_runs):
        for j in range(i + 1, n_runs):
            sim = np.zeros((n_topics, n_topics))
            for a in range(n_topics):
                for b in range(n_topics):
                    sim[a, b] = jaccard(all_term_sets[i][a], all_term_sets[j][b])
            row_ind, col_ind = linear_sum_assignment(-sim)
            matched = sim[row_ind, col_ind]
            mean_j = float(np.mean(matched))
            min_j  = float(np.min(matched))
            pair_means.append(mean_j)
            stab_rows.append({
                "seed_a": seeds_used[i],
                "seed_b": seeds_used[j],
                "mean_jaccard": mean_j,
                "min_jaccard":  min_j,
                "n_topics": n_topics
            })

            # v0.3.1: when i == 0, the row_ind/col_ind pairing maps
            # primary topics to seed j. row_ind[t] gives the primary topic
            # index (always an identity permutation since rows of -sim are
            # the primary topics), and matched[t] is its best-match Jaccard
            # in seed j. Store by primary topic index (row_ind[t]).
            if i == 0:
                # Column j-1 because j ranges over 1..n_runs-1 when i==0.
                for t in range(n_topics):
                    primary_matches[row_ind[t], j - 1] = matched[t]

    stab_df = pd.DataFrame(stab_rows)
    stab_df.to_csv(stab_path, index=False)
    print("LITDISCOVER: wrote", stab_path,
          "(overall mean Jaccard =", round(float(np.mean(pair_means)), 3), ")")

    # v0.3.1: write the per-topic stability file. Path comes from the
    # Stata local stabtopiccsv; if absent (older .ado), skip silently.
    stab_topic_path = Macro.getLocal("stabtopiccsv")
    if stab_topic_path:
        topic_stab_rows = []
        for t_idx in range(n_topics):
            row_vals = primary_matches[t_idx, :]
            topic_stab_rows.append({
                "topic":           t_idx + 1,
                "mean_best_match": float(np.mean(row_vals)),
                "min_best_match":  float(np.min(row_vals)),
                "n_seed_pairs":    int(n_runs - 1),
            })
        topic_stab_df = pd.DataFrame(topic_stab_rows)
        topic_stab_df.to_csv(stab_topic_path, index=False)
        print("LITDISCOVER: wrote", stab_topic_path)

# UMass coherence (primary run)
if do_coh:
    print("LITDISCOVER: computing UMass coherence")
    Xb = (X > 0).astype(int)
    Xb_csc = Xb.tocsc()
    n_docs = Xb.shape[0]
    eps = 1.0

    def doc_freq(term_id):
        return int(Xb_csc[:, term_id].sum())

    def co_doc_freq(t1, t2):
        col1 = Xb_csc[:, t1]
        col2 = Xb_csc[:, t2]
        return int((col1.multiply(col2)).sum())

    coh_rows = []
    for topic_idx, comp in enumerate(primary_model.components_, start=1):
        top_ids = comp.argsort()[::-1][:topn]
        score = 0.0
        pairs = 0
        for m_idx in range(1, len(top_ids)):
            for l_idx in range(0, m_idx):
                tm = top_ids[m_idx]
                tl = top_ids[l_idx]
                d_l = doc_freq(tl)
                d_ml = co_doc_freq(tm, tl)
                if d_l == 0:
                    continue
                score += np.log((d_ml + eps) / d_l)
                pairs += 1
        umass = float(score / pairs) if pairs > 0 else float("nan")
        coh_rows.append({"topic": topic_idx, "umass": umass, "topn": topn})
    coh_df = pd.DataFrame(coh_rows)
    coh_df.to_csv(coh_path, index=False)
    print("LITDISCOVER: wrote", coh_path)

# Model info
model_out = pd.DataFrame([{
    "n_docs": int(df.shape[0]),
    "vocab_size": int(X.shape[1]),
    "topics": int(n_topics),
    "seed": int(seed_val),
    "minfreq": int(minfreq_val),
    "maxdf": float(maxdf_val),
    "ngram": int(ngram_val),
    "seeds": int(n_seeds),
    "coherence_computed": int(1 if do_coh else 0)
}])
model_out.to_csv(model_path, index=False)
print("LITDISCOVER: wrote", model_path)

# ---------------------------------------------------------------------
# Block A.5 addition: pyLDAvis-ready interchange file
#
# When the Stata local pyldavispath is non-empty, derive the five
# arrays that pyLDAvis.prepare() requires from the primary-seed model
# and save them as a single compressed NumPy file. The visualisation
# helper (litdiscover_viz.py) then loads this file and calls
# pyLDAvis.prepare() directly, with no LDA re-fit and no scikit-learn
# version coupling. The file is written via a binary file object so
# that NumPy does not append ".npz" to the Stata-supplied path.
# ---------------------------------------------------------------------
if pyldavis_path:
    print("LITDISCOVER: deriving pyLDAvis inputs from primary-seed model")
    comp = primary_model.components_.astype(np.float64)
    row_sums = comp.sum(axis=1, keepdims=True)
    row_sums[row_sums == 0] = 1.0
    topic_term_dists = comp / row_sums
    doc_topic_dists  = doc_topic.astype(np.float64)
    doc_lengths      = np.asarray(X.sum(axis=1)).flatten().astype(np.int64)
    term_frequency   = np.asarray(X.sum(axis=0)).flatten().astype(np.int64)
    vocab_arr        = np.asarray(terms, dtype=str)

    with open(pyldavis_path, "wb") as _fh:
        np.savez_compressed(
            _fh,
            topic_term_dists=topic_term_dists,
            doc_topic_dists=doc_topic_dists,
            doc_lengths=doc_lengths,
            vocab=vocab_arr,
            term_frequency=term_frequency,
        )
    print("LITDISCOVER: wrote pyLDAvis inputs to", pyldavis_path)
