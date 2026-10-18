"""readability.py counts what a reader meets as prose, and nothing else."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "skills" / "doc-audit"))

from readability import PARAGRAPH_BUDGET, TASK_BUDGET, measure  # noqa: E402


def words(n: int, last: str = "end.") -> str:
    return " ".join(["word"] * (n - 1) + [last])


class WhatIsProse(unittest.TestCase):
    def test_a_fenced_block_is_not_prose(self) -> None:
        found = measure("One short sentence here.\n\n```\nif x: run this now.\n```\n")
        self.assertEqual(found.words, 4)
        self.assertEqual(found.sentences, [4])

    def test_a_yaml_header_is_not_prose(self) -> None:
        header = "---\nname: a-skill\ndescription: Many words that describe it.\n---\n"
        text = header + "\nTwo words.\n"
        self.assertEqual(measure(text).words, 2)

    def test_a_table_is_not_prose(self) -> None:
        table = "| setting | default |\n|---|---|\n| `A_NAME` | a cell of words |\n"
        self.assertEqual(measure(table).words, 0)

    def test_a_heading_is_counted_as_a_heading_not_as_prose(self) -> None:
        found = measure("# A title of five words\n\nThree words here.\n")
        self.assertEqual((found.words, found.headings), (3, 1))

    def test_a_list_item_is_a_paragraph_of_its_own(self) -> None:
        # An item with no full stop must not run into the next one as one long sentence.
        found = measure("- the first item has no stop\n- the second has none either\n")
        self.assertEqual(found.sentences, [6, 5])

    def test_a_list_marker_and_a_task_box_are_not_words(self) -> None:
        text = "1. Three words here.\n- [ ] Three more here.\n- [x] And three more.\n"
        found = measure(text)
        self.assertEqual(found.words, 9)

    def test_a_wrapped_paragraph_is_one_paragraph(self) -> None:
        found = measure("The first line of a\nsentence goes on here.\n")
        self.assertEqual(found.sentences, [9])

    def test_a_quote_is_prose_without_its_marker(self) -> None:
        self.assertEqual(measure("> Quoted words count too.\n").words, 4)

    def test_a_diagram_and_an_image_are_pictures(self) -> None:
        text = "```mermaid\nflowchart LR\n  a --> b\n```\n\n![a tile](tile.png)\n"
        self.assertEqual(measure(text).pictures, 2)


class Sentences(unittest.TestCase):
    def test_a_sentence_ends_at_a_stop_before_a_capital(self) -> None:
        found = measure("It runs today. Then it stops! Does it stop? Yes, it does.\n")
        self.assertEqual(found.sentences, [3, 3, 3, 3])

    def test_a_stop_before_a_lowercase_word_does_not_end_one(self) -> None:
        found = measure("Use a short name, e.g. the noun it holds.\n")
        self.assertEqual(found.sentences, [9])

    def test_a_fragment_under_three_words_is_not_a_sentence(self) -> None:
        found = measure("Done. This one counts as a sentence.\n")
        self.assertEqual(found.sentences, [6])

    def test_the_average_is_over_sentences(self) -> None:
        self.assertEqual(measure("One two three four. Five six.\n").average, 4)


class Budgets(unittest.TestCase):
    def test_a_paragraph_over_budget_is_reported_with_its_line(self) -> None:
        text = "A short one.\n\n" + words(PARAGRAPH_BUDGET + 1) + "\n"
        self.assertEqual([line for line, _ in measure(text).over], [3])

    def test_a_paragraph_on_budget_is_not_over(self) -> None:
        self.assertEqual(measure(words(PARAGRAPH_BUDGET) + "\n").over, [])

    def test_a_task_item_has_the_larger_budget(self) -> None:
        task = "- [ ] " + words(PARAGRAPH_BUDGET + 10)
        self.assertEqual(measure(task + "\n").over, [])
        self.assertEqual(len(measure("- [ ] " + words(TASK_BUDGET + 1) + "\n").over), 1)


if __name__ == "__main__":
    unittest.main()
