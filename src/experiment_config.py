from __future__ import annotations

import json
from pathlib import Path

from nfcorpus_loader import (
    DEFAULT_DATA_DIR,
    NFCORPUS_SPLITS,
    NFCORPUS_URL,
    RAG_QUERY_SAMPLE_SIZE,
    RAG_QUERY_SEED,
)

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"
NFCORPUS_DIR = DEFAULT_DATA_DIR
RESULTS_DIR = PROJECT_ROOT / "result" / "tp2"
EMBEDDINGS_DIR = DATA_DIR / "embeddings"
PLOTS_DIR = PROJECT_ROOT / "plots" / "tp2"
CONFIG_PATH = PROJECT_ROOT / "config" / "tp2_experiment.json"

LEXICAL_RESULTS_PATH = RESULTS_DIR / "results_lexical.csv"
SEMANTIC_RESULTS_PATH = RESULTS_DIR / "results_semantic.csv"
HYBRID_RESULTS_PATH = RESULTS_DIR / "results_hybrid.csv"
RERANKING_RESULTS_PATH = RESULTS_DIR / "results_reranking.csv"
METRICS_PER_QUERY_PATH = RESULTS_DIR / "metrics_per_query.csv"
TYPO_EXPERIMENT_PATH = RESULTS_DIR / "typo_experiment.csv"
RAG_EXPERIMENT_PATH = RESULTS_DIR / "rag_experiment.csv"

TUNING_SPLIT = "dev"
FINAL_SPLIT = "test"
EVALUATION_CUTOFF = 10
RANKING_DEPTH = 100
FUSION_DEPTH = 100
RERANK_DEPTH = 50
RRF_K_CANDIDATES = (10, 60, 100)

RAG_QUERY_IDS = (
    "PLAIN-68",
    "PLAIN-2450",
    "PLAIN-153",
    "PLAIN-2850",
    "PLAIN-2750",
    "PLAIN-270",
    "PLAIN-2470",
    "PLAIN-2430",
    "PLAIN-238",
    "PLAIN-3342",
)


def default_experiment_config() -> dict:
    return {
        "status": "pending_dev_tuning",
        "protocol": {
            "dataset": "NFCorpus",
            "source": NFCORPUS_URL,
            "splits": list(NFCORPUS_SPLITS),
            "document_representation": "title + text",
            "tuning_split": TUNING_SPLIT,
            "final_split": FINAL_SPLIT,
            "evaluation_cutoff": EVALUATION_CUTOFF,
            "ranking_depth": RANKING_DEPTH,
            "fusion_depth": FUSION_DEPTH,
            "rerank_depth": RERANK_DEPTH,
            "rrf_k_candidates": list(RRF_K_CANDIDATES),
            "rag_query_seed": RAG_QUERY_SEED,
            "rag_query_sample_size": RAG_QUERY_SAMPLE_SIZE,
            "rag_query_ids": list(RAG_QUERY_IDS),
        },
        "selected": {
            "preprocessing": None,
            "lexical_model": None,
            "bm25_k1": None,
            "bm25_b": None,
            "typo_kgram_size": None,
            "typo_jaccard_threshold": None,
            "typo_edit_distance_threshold": None,
            "embedding_model": None,
            "rrf_k": None,
            "reranker_model": None,
            "llm": None,
            "llm_temperature": 0,
            "llm_max_tokens": None,
            "rag_language": None,
        },
    }


def load_experiment_config(path: str | Path = CONFIG_PATH) -> dict:
    config_path = Path(path)
    with config_path.open(encoding="utf-8") as config_file:
        return json.load(config_file)


def save_experiment_config(config: dict, path: str | Path = CONFIG_PATH) -> Path:
    config_path = Path(path)
    config_path.parent.mkdir(parents=True, exist_ok=True)
    with config_path.open("w", encoding="utf-8") as config_file:
        json.dump(config, config_file, indent=2, ensure_ascii=False)
        config_file.write("\n")
    return config_path


def ensure_experiment_config(path: str | Path = CONFIG_PATH) -> dict:
    config_path = Path(path)
    if not config_path.exists():
        save_experiment_config(default_experiment_config(), config_path)
    return load_experiment_config(config_path)
