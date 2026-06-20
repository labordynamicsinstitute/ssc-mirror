"""littext_state: persist pipeline state to a per-user cache directory.
"""

from __future__ import annotations

import os
import pickle
import tempfile
from typing import Any, Dict

import numpy as np
import pandas as pd


def _state_path() -> str:
    return os.path.join(tempfile.gettempdir(), "littext_state.pkl")


def save_state(
    constructs_df: pd.DataFrame,
    construct_embeddings: np.ndarray,
    relations_df: pd.DataFrame,
    diag_df: pd.DataFrame,
) -> None:
    state = {
        "constructs_df": constructs_df,
        "construct_embeddings": construct_embeddings,
        "relations_df": relations_df,
        "diag_df": diag_df,
    }
    with open(_state_path(), "wb") as fh:
        pickle.dump(state, fh)


def load_state() -> Dict[str, Any]:
    path = _state_path()
    if not os.path.exists(path):
        raise RuntimeError(
            "littext: no cached state found. Run -littext analyze- before requesting a figure."
        )
    with open(path, "rb") as fh:
        return pickle.load(fh)
