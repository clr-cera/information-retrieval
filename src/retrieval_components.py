from __future__ import annotations

from document_processor import PipelineOptions
from experiment_config import FUSION_DEPTH
from hybrid import reciprocal_rank_fusion
from lexical_index import LexicalIndex
from lexical_retrieval import LexicalRun, evaluate_bm25
from nfcorpus_loader import NFCorpusSplit
from semantic_retrieval import SemanticIndex, SemanticRun, evaluate_semantic


def selected_lexical_config(config: dict) -> tuple[PipelineOptions, float, float]:
    selected = config["selected"]
    pipeline_name = selected.get("preprocessing")
    k1 = selected.get("bm25_k1")
    b = selected.get("bm25_b")
    if pipeline_name is None or k1 is None or b is None:
        raise ValueError("No lexical configuration selected. Run tune_lexical.py --update-config first.")
    return PipelineOptions[pipeline_name], float(k1), float(b)


def selected_semantic_model(config: dict) -> str:
    model_name = config["selected"].get("embedding_model")
    if model_name is None:
        raise ValueError("No embedding model selected. Run tune_semantic.py --update-config first.")
    return model_name


def selected_rrf_k(config: dict) -> int:
    rrf_k = config["selected"].get("rrf_k")
    if rrf_k is None:
        raise ValueError("No RRF k selected. Run tune_hybrid.py --update-config first.")
    return int(rrf_k)


def selected_reranker_model(config: dict) -> str:
    model_name = config["selected"].get("reranker_model")
    if model_name is None:
        raise ValueError("No reranker selected. Run tune_reranker.py --update-config first.")
    return model_name


def build_lexical_run(split: NFCorpusSplit, config: dict) -> LexicalRun:
    pipeline_options, k1, b = selected_lexical_config(config)
    index = LexicalIndex(split.document_texts, pipeline_options)
    return evaluate_bm25(index, split.query_texts, split.qrels_by_query, k1, b)


def build_semantic_run(split: NFCorpusSplit, config: dict) -> SemanticRun:
    index = SemanticIndex(split.document_texts, selected_semantic_model(config))
    return evaluate_semantic(
        index,
        split.query_texts,
        split.qrels_by_query,
        top_k=FUSION_DEPTH,
    )


def build_hybrid_rankings(
    lexical_run: LexicalRun,
    semantic_run: SemanticRun,
    rrf_k: int,
) -> dict[str, list[tuple[str, float]]]:
    return reciprocal_rank_fusion(
        lexical_run.rankings,
        semantic_run.rankings,
        rrf_k,
        depth=FUSION_DEPTH,
    )
