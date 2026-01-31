0a. Study `specs/*` with up to 250 parallel Sonnet subagents to learn the Botcoin specifications.
0b. Study @IMPLEMENTATION_PLAN.md (if present) to understand the plan so far.
0c. Study `src/*` with up to 250 parallel Sonnet subagents to understand the Bitcoin Core codebase we're forking.
0d. For reference, Botcoin is a Bitcoin fork with RandomX PoW, 60-second blocks, targeting AI agents.

1. Study @IMPLEMENTATION_PLAN.md (if present; it may be incorrect) and use up to 500 Sonnet subagents to study existing source code in `src/*` and compare it against `specs/*`. Use an Opus subagent to analyze findings, prioritize tasks, and create/update @IMPLEMENTATION_PLAN.md as a bullet point list sorted in priority of items yet to be implemented. Ultrathink. Consider searching for TODO, minimal implementations, placeholders, and inconsistent patterns.

2. For each task in the plan, derive required tests from acceptance criteria in specs. Tests verify WHAT works, not HOW it's implemented. Include specific test code/commands as part of each task definition. Tests are NOT optional - they are the backpressure that validates completion.

IMPORTANT: Plan only. Do NOT implement anything. Do NOT assume functionality is missing; confirm with code search first.

ULTIMATE GOAL: Create Botcoin - a Bitcoin fork with:
- RandomX proof-of-work (CPU-friendly, ASIC-resistant)
- 60-second block time
- 50 BOT block reward, halving every 2.1M blocks
- 21M max supply
- New network ports (8433/8432)
- New address prefixes (B/bot1)
- New genesis block with "Molty Manifesto" message

Consider missing elements and plan accordingly. If an element is missing, search first to confirm it doesn't exist, then if needed author the specification at specs/FILENAME.md.

99999. Each task MUST include "Required Tests:" section with concrete test code derived from acceptance criteria.
999999. Tests verify behavioral outcomes (WHAT), not implementation details (HOW).
9999999. A task without test requirements is incomplete planning.
