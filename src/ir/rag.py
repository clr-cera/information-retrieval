"""Retrieval-Augmented Generation: prompts and calls to a local LLM served by Ollama.

The LLM runs locally through Ollama (https://ollama.com). The HTTP API is called with the
standard library only (urllib + json), so no extra dependency is needed.

Two conditions are compared, with the same model and the same parameters:
- condition A (without RAG): the model receives only the question;
- condition B (with RAG): the model receives the question and the top-5 documents after
  reranking, each one with its identifier.
"""

from __future__ import annotations

import json
import urllib.request
from dataclasses import dataclass
from time import perf_counter

OLLAMA_URL = "http://localhost:11434/api/chat"
LLM_SEED = 42
ANSWER_WORD_LIMIT = 150
REQUEST_TIMEOUT_SECONDS = 1800
# Context window of the model. The default of Ollama is small, and a longer prompt would be cut
# silently; 16384 tokens fit the 5 documents, the reasoning and the answer.
CONTEXT_WINDOW_TOKENS = 16384

SYSTEM_MESSAGE = "You are an assistant that answers questions about nutrition and health."


@dataclass(frozen=True)
class LLMAnswer:
    text: str
    seconds: float
    prompt_tokens: int
    generated_tokens: int
    finished: bool


def build_prompt_without_context(question: str) -> str:
    """Prompt of condition A: only the question."""
    lines = [
        f"Answer the question below in English, in at most {ANSWER_WORD_LIMIT} words.",
        "",
        f"Question: {question}",
    ]
    return "\n".join(lines)


def build_prompt_with_context(question: str, documents: list[tuple[str, str]]) -> str:
    """Prompt of condition B: the question and the retrieved documents.

    documents is a list of (doc_id, text) in rank order.
    """
    lines = [
        "Answer the question below in English, in at most "
        f"{ANSWER_WORD_LIMIT} words, using only the information in the documents provided.",
        "Rules:",
        "- Base every statement on the documents; do not use outside knowledge.",
        "- Cite the documents you used by their identifiers in square brackets, for example [MED-123].",
        "- If the documents do not contain enough evidence to answer, say so clearly.",
        "",
        "Documents:",
    ]
    for doc_id, text in documents:
        lines.append(f"[{doc_id}] {text}")
        lines.append("")
    lines.append(f"Question: {question}")
    return "\n".join(lines)


def ask_llm(prompt: str, model: str, temperature: float, max_tokens: int) -> LLMAnswer:
    """Send one prompt to the Ollama chat API and return the final answer.

    Qwen3 models reason before answering. With "think": true, Ollama returns the reasoning in a
    separate field, so only the final answer (message.content) is kept. max_tokens limits the
    reasoning and the answer together.
    """
    body = {
        "model": model,
        "stream": False,
        "think": True,
        "options": {
            "temperature": temperature,
            "seed": LLM_SEED,
            "num_predict": max_tokens,
            "num_ctx": CONTEXT_WINDOW_TOKENS,
        },
        "messages": [
            {"role": "system", "content": SYSTEM_MESSAGE},
            {"role": "user", "content": prompt},
        ],
    }
    request = urllib.request.Request(
        OLLAMA_URL,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )

    start = perf_counter()
    with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
        result = json.loads(response.read().decode("utf-8"))
    seconds = perf_counter() - start

    return LLMAnswer(
        text=result["message"]["content"].strip(),
        seconds=seconds,
        prompt_tokens=int(result.get("prompt_eval_count", 0)),
        generated_tokens=int(result.get("eval_count", 0)),
        finished=result.get("done_reason") == "stop",
    )
