"""Prose measurements for Markdown documents: what a reader meets, in numbers.

Usage: python3 readability.py SUMMARY.md [...] [--detail EVIDENCE.md ...]

For each file: words, sentences, the average sentence and the long ones, the paragraphs over
budget with their line numbers, headings and pictures. Fenced blocks and table rows are not
prose and are left out. A list item is a paragraph of its own; a task item (`- [ ]`), which
carries a spec and its done-means, has a budget of its own. The budgets bind the summary tiers;
files after --detail are evidence, measured for information and marked so. A measuring tool,
not a gate: it always exits 0.
"""

import re
import statistics
import sys
from pathlib import Path

SENTENCE_BUDGET = 22
LONG_SENTENCE = 40
PARAGRAPH_BUDGET = 150
TASK_BUDGET = 250

LIST_ITEM = re.compile(r"^\s*(?:[-*+]|\d+\.)\s")
TASK_ITEM = re.compile(r"^\s*[-*+]\s\[[ xX]\]")
SENTENCE_END = re.compile(r"(?<=[.!?])\s+(?=[A-Z`*_(\[\"'])")


def blocks(text: str) -> tuple[list[tuple[int, str]], int, int]:
    """The prose blocks with their first line number, the headings and the pictures."""
    found: list[tuple[int, str]] = []
    current: list[str] = []
    start = 0
    headings = pictures = 0
    fenced = False

    def close() -> None:
        if current:
            found.append((start, " ".join(current)))
            current.clear()

    for number, line in enumerate(text.splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith("```"):
            if not fenced and stripped.startswith("```mermaid"):
                pictures += 1
            fenced = not fenced
            close()
            continue
        if fenced:
            continue
        pictures += line.count("![")
        if not stripped or stripped.startswith("|"):
            close()
            continue
        if stripped.startswith("#"):
            headings += 1
            close()
            continue
        if LIST_ITEM.match(line) or not current:
            close()
            start = number
        current.append(stripped.lstrip("> "))
    close()
    return found, headings, pictures


def report(path: Path, detail: bool = False) -> list[str]:
    prose, headings, pictures = blocks(path.read_text())
    lengths = [
        len(sentence.split())
        for _, block in prose
        for sentence in SENTENCE_END.split(block)
        if len(sentence.split()) > 2
    ]
    words = sum(len(block.split()) for _, block in prose)
    average = statistics.mean(lengths) if lengths else 0.0
    over = [
        (number, block)
        for number, block in prose
        if len(block.split()) > (TASK_BUDGET if TASK_ITEM.match(block) else PARAGRAPH_BUDGET)
    ]
    if detail:
        return [
            f"{path}: {words:,} words, {len(lengths)} sentences, {average:.1f} words a sentence,"
            f" {sum(n > LONG_SENTENCE for n in lengths)} over {LONG_SENTENCE}; {len(over)}"
            " paragraphs over the summary budget; evidence tier, budgets advisory"
        ]
    lines = [
        f"{path}: {words:,} words, {len(lengths)} sentences, {average:.1f} words a sentence"
        f" (budget {SENTENCE_BUDGET}), {sum(n > LONG_SENTENCE for n in lengths)} over"
        f" {LONG_SENTENCE}; {len(over)} paragraphs over budget; {headings} headings,"
        f" {pictures} pictures"
    ]
    lines += [f"  line {number}: {len(block.split())} words: {block[:70]}" for number, block in over]
    return lines


def main(args: list[str]) -> int:
    detail = False
    for arg in args:
        if arg == "--detail":
            detail = True
            continue
        print("\n".join(report(Path(arg), detail)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
