# Pattern Confidence

**Last Updated:** [date]

---

## Overview

The confidence register: every pattern in semantic memory, filed by how many times
it has actually held up. `/learn` moves a pattern between sections as it accumulates
examples; `/grow` reads the counts to report brain health.

**Confidence is a function of example count, not of how sure it felt.** Trust the
number - a pattern that has happened once is LOW even if it seems obviously right.

| Level | Examples | Meaning |
|-------|----------|---------|
| LOW | 1 | Observed once. May be a coincidence. |
| MEDIUM | 2-4 | Repeated. Worth suggesting, still worth checking. |
| HIGH | 5+ | Reliable. Apply proactively. |

Promotion is checked on every `/learn` reinforcement. A pattern never demotes on its
own - remove it deliberately if it stops being true.

---

## HIGH Confidence (5+ examples)

<!-- Format:
- **Pattern name** - `memory/semantic/patterns/<domain>-patterns.md#<slug>`
  Examples: 5 | Promoted: YYYY-MM-DD | Last reinforced: YYYY-MM-DD
  Time saved per application: ~X min
-->

*None yet.*

---

## MEDIUM Confidence (2-4 examples)

*None yet.*

---

## LOW Confidence (1 example)

*None yet.*

---

## Promotion Log

Newest last. One line per promotion - this is what `/grow` reports as milestones.

<!-- Format:
- YYYY-MM-DD: **Pattern name** LOW -> MEDIUM (2nd example: <what happened>)
-->

---

## Retired Patterns

Patterns removed because they stopped being true. Keep the reason - a pattern that
failed teaches as much as one that held.

<!-- Format:
- **Pattern name** - retired YYYY-MM-DD
  Was: HIGH (6 examples) | Reason: <what changed>
-->

*None yet.*
