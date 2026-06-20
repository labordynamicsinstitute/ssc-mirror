"""littext_embed: produce vector embeddings of candidate constructs.
"""

from __future__ import annotations

from typing import List

import numpy as np


_MODEL_CACHE: dict = {}


def _get_model(model_name: str):
    """Cache the sentence-transformer model across calls within a Stata session."""
    if model_name in _MODEL_CACHE:
        return _MODEL_CACHE[model_name]
    from sentence_transformers import SentenceTransformer
    model = SentenceTransformer(model_name)
    _MODEL_CACHE[model_name] = model
    return model


def embed_constructs(surface_forms: List[str], model_name: str = "all-MiniLM-L6-v2") -> np.ndarray:
    """Return an (n_constructs, d) array of L2-normalised embeddings."""
    if not surface_forms:
        return np.zeros((0, 384), dtype=np.float32)
    model = _get_model(model_name)
    emb = model.encode(
        surface_forms,
        batch_size=64,
        show_progress_bar=False,
        convert_to_numpy=True,
        normalize_embeddings=True,
    )
    return emb.astype(np.float32)
