from __future__ import annotations

import argparse
import csv
import random
from dataclasses import asdict, dataclass
from itertools import product

from nltk.corpus import stopwords

from experiment_config import RESULTS_DIR, load_experiment_config, save_experiment_config
from nfcorpus_loader import load_split
from typo_correction import (
    ERROR_TYPES,
    SpellingCorrector,
    build_dictionary,
    inject_query_error,
    levenshtein_distance,
)

STOPWORDS = set(stopwords.words("english"))


@dataclass(frozen=True)
class TypoTuningRow:
    kgram_size: int
    jaccard_threshold: float
    max_edit_distance: int
    accuracy: float
    mean_corrected_distance: float
    sample_count: int


def build_evaluation_pairs(split, dictionary, sample_size: int, seed: int):
    rng = random.Random(seed)
    pairs = []
    for index, query_id in enumerate(sorted(split.queries)):
        if len(pairs) >= sample_size:
            break
        injected = inject_query_error(
            split.queries[query_id].text,
            ERROR_TYPES[index % len(ERROR_TYPES)],
            dictionary,
            rng=rng,
            excluded_tokens=STOPWORDS,
        )
        if injected is not None:
            pairs.append((injected.erroneous_token, injected.original_token))
    return pairs


def main() -> None:
    parser = argparse.ArgumentParser(description="Tune typo-correction parameters on dev.")
    parser.add_argument("--split", default="dev")
    parser.add_argument("--samples", type=int, default=200)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--update-config", action="store_true")
    args = parser.parse_args()

    split = load_split(args.split)
    dictionary = build_dictionary(split.document_texts)
    pairs = build_evaluation_pairs(split, dictionary, args.samples, args.seed)
    if not pairs:
        raise SystemExit("Could not build any evaluation errors.")

    rows: list[TypoTuningRow] = []
    for kgram_size, jaccard_threshold, max_edit_distance in product(
        (2, 3),
        (0.2, 0.3, 0.4, 0.5),
        (1, 2, 3),
    ):
        corrector = SpellingCorrector(
            dictionary,
            kgram_size=kgram_size,
            jaccard_threshold=jaccard_threshold,
            max_edit_distance=max_edit_distance,
        )
        corrected = [corrector.correct_token(erroneous) for erroneous, _ in pairs]
        exact = sum(
            correction == original
            for correction, (_, original) in zip(corrected, pairs)
        )
        mean_distance = sum(
            levenshtein_distance(correction, original)
            for correction, (_, original) in zip(corrected, pairs)
        ) / len(pairs)
        row = TypoTuningRow(
            kgram_size=kgram_size,
            jaccard_threshold=jaccard_threshold,
            max_edit_distance=max_edit_distance,
            accuracy=exact / len(pairs),
            mean_corrected_distance=mean_distance,
            sample_count=len(pairs),
        )
        rows.append(row)
        print(
            f"k={kgram_size} jaccard={jaccard_threshold} "
            f"max_distance={max_edit_distance} "
            f"accuracy={row.accuracy:.4f} mean_distance={row.mean_corrected_distance:.4f}"
        )

    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    output_path = RESULTS_DIR / f"typo_tuning_{args.split}.csv"
    with output_path.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=list(asdict(rows[0])))
        writer.writeheader()
        writer.writerows(asdict(row) for row in rows)

    best = max(
        rows,
        key=lambda row: (
            row.accuracy,
            -row.mean_corrected_distance,
            -row.kgram_size,
            -row.max_edit_distance,
            -row.jaccard_threshold,
        ),
    )
    print(
        "Selected on "
        f"{args.split}: k={best.kgram_size}, "
        f"jaccard={best.jaccard_threshold}, "
        f"max_distance={best.max_edit_distance}, "
        f"accuracy={best.accuracy:.4f}"
    )
    print(f"Tuning results written to {output_path}")

    if args.update_config:
        config = load_experiment_config()
        config["selected"]["typo_kgram_size"] = best.kgram_size
        config["selected"]["typo_jaccard_threshold"] = best.jaccard_threshold
        config["selected"]["typo_edit_distance_threshold"] = best.max_edit_distance
        config["status"] = "lexical_and_typo_tuned"
        save_experiment_config(config)
        print("Updated config/tp2_experiment.json with the selected typo parameters")


if __name__ == "__main__":
    main()
