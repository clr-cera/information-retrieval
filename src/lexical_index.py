from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from time import perf_counter

from document_processor import PipelineOptions
from posting_list import PostingList
from probabilistic_model import ProbabilisticModel


@dataclass(frozen=True)
class IndexStats:
    document_count: int
    vocabulary_size: int
    posting_count: int
    build_time_seconds: float
    average_document_length: float

    def as_dict(self) -> dict[str, float | int]:
        return {
            "document_count": self.document_count,
            "vocabulary_size": self.vocabulary_size,
            "posting_count": self.posting_count,
            "build_time_seconds": self.build_time_seconds,
            "average_document_length": self.average_document_length,
        }


class LexicalIndex:
    def __init__(
        self,
        documents: Mapping[str, str],
        pipeline_options: PipelineOptions,
    ):
        self.pipeline_options = pipeline_options
        start = perf_counter()
        self.posting_list = PostingList(pipeline_options)
        self.posting_list.add_documents(dict(documents))
        self.build_time_seconds = perf_counter() - start

    @property
    def stats(self) -> IndexStats:
        document_lengths = self.posting_list.document_lengths
        document_count = len(document_lengths)
        average_document_length = (
            sum(document_lengths.values()) / document_count if document_count else 0.0
        )
        return IndexStats(
            document_count=document_count,
            vocabulary_size=len(self.posting_list.postings),
            posting_count=sum(
                len(postings) for postings in self.posting_list.postings.values()
            ),
            build_time_seconds=self.build_time_seconds,
            average_document_length=average_document_length,
        )

    def build_bm25(self, k1: float, b: float) -> ProbabilisticModel:
        return ProbabilisticModel(
            self.posting_list,
            self.pipeline_options,
            k=k1,
            b=b,
        )
