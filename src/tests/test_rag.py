"""Testes de ir.rag (montagem dos prompts; não chamam a LLM)."""

from ir.rag import ANSWER_WORD_LIMIT, build_prompt_with_context, build_prompt_without_context


def test_prompt_without_context_has_only_the_question():
    prompt = build_prompt_without_context("Is coffee healthy?")

    assert "Question: Is coffee healthy?" in prompt
    assert f"at most {ANSWER_WORD_LIMIT} words" in prompt
    assert "Documents:" not in prompt


def test_prompt_with_context_lists_documents_with_identifiers_in_order():
    documents = [("MED-1", "Coffee and health. Text one."), ("MED-2", "Caffeine. Text two.")]

    prompt = build_prompt_with_context("Is coffee healthy?", documents)

    assert "[MED-1] Coffee and health. Text one." in prompt
    assert "[MED-2] Caffeine. Text two." in prompt
    assert prompt.index("[MED-1]") < prompt.index("[MED-2]")
    assert prompt.strip().endswith("Question: Is coffee healthy?")


def test_prompt_with_context_asks_for_sources_and_insufficient_evidence():
    prompt = build_prompt_with_context("Is coffee healthy?", [("MED-1", "Text.")])

    assert "only the information in the documents" in prompt
    assert "Cite the documents" in prompt
    assert "not contain enough evidence" in prompt
