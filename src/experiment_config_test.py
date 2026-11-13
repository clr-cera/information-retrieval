from experiment_config import (
    RAG_QUERY_IDS,
    default_experiment_config,
    ensure_experiment_config,
    load_experiment_config,
    save_experiment_config,
)


def test_default_config_encodes_frozen_protocol():
    config = default_experiment_config()
    protocol = config["protocol"]

    assert protocol["tuning_split"] == "dev"
    assert protocol["final_split"] == "test"
    assert protocol["document_representation"] == "title + text"
    assert protocol["evaluation_cutoff"] == 10
    assert protocol["ranking_depth"] == 100
    assert protocol["fusion_depth"] == 100
    assert protocol["rerank_depth"] == 50
    assert protocol["rrf_k_candidates"] == [10, 60, 100]
    assert protocol["rag_query_seed"] == 42
    assert protocol["rag_query_ids"] == list(RAG_QUERY_IDS)


def test_rag_query_ids_are_unique_and_complete():
    assert len(RAG_QUERY_IDS) == 10
    assert len(set(RAG_QUERY_IDS)) == 10


def test_config_round_trip(tmp_path):
    path = tmp_path / "nested" / "tp2_experiment.json"
    config = default_experiment_config()
    config["selected"]["lexical_model"] = "BM25"

    save_experiment_config(config, path)

    assert path.is_file()
    assert load_experiment_config(path) == config


def test_ensure_experiment_config_creates_default_file(tmp_path):
    path = tmp_path / "tp2_experiment.json"

    config = ensure_experiment_config(path)

    assert path.is_file()
    assert config == default_experiment_config()
