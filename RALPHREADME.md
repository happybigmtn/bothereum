# Ralph Development Guide

One context window. One task. Fresh each iteration.

> "Deliberate allocation in an undeterministic world."

---

## Core Philosophy

Ralph maximizes LLM effectiveness through:

- **Context discipline** — Stay in the "smart zone" (40-60% of ~176K usable tokens)
- **Single-task focus** — One goal per iteration, then context reset
- **Subagent memory extension** — Fan out to avoid polluting main context
- **Backpressure-driven quality** — Tests reject invalid work, forcing correction
- **Human ON the loop, not IN it** — Engineer the environment, not the execution
- **Let Ralph Ralph** — Trust self-identification, self-correction, self-improvement

---

## Three Phases, Two Prompts, One Loop

### Phase 1: Define Requirements (Human + LLM Conversation)

Create specifications that define **WHAT**, not HOW:

```
specs/
├── consensus.md      # One spec per topic of concern
├── randomx.md        # Behavioral outcomes, observable results
└── addresses.md      # Acceptance criteria derive tests
```

**Topic Scope Test**: Describe it in one sentence without "and"
- ✓ "The RandomX system validates proof-of-work using CPU-optimized hashing"
- ✗ "The network handles blocks, transactions, and peer connections" → 3 topics

**Acceptance Criteria** define observable, verifiable outcomes:
- ✓ "Address starts with 'B' for P2PKH"
- ✓ "Block validates if RandomX hash meets difficulty target"
- ✗ "Uses K-means clustering" (that's implementation, not outcome)

### Phase 2: Planning Mode

```bash
./loopclaude.sh plan              # Full planning
./loopclaude.sh plan-work "scope" # Scoped planning
```

**What happens:**
1. Subagents study `specs/*` (requirements)
2. Subagents study `src/*` (current state)
3. Gap analysis: compare specs vs code
4. **Derive test requirements from acceptance criteria**
5. Create prioritized `IMPLEMENTATION_PLAN.md`
6. **No implementation** — planning only

### Phase 3: Building Mode

```bash
./loopclaude.sh        # Build until done
./loopclaude.sh 20     # Max 20 iterations
```

**Each iteration:**
1. **Orient** — Study specs with subagents
2. **Read plan** — Pick most important unchecked task
3. **Investigate** — Search codebase (don't assume not implemented!)
4. **Implement** — Code + required tests (TDD approach)
5. **Validate** — Run tests (backpressure)
6. **Update plan** — Mark done, note discoveries
7. **Commit** — Only when tests pass
8. **Loop ends** — Context cleared, next iteration fresh

---

## ⚠️ CRITICAL: Backpressure & Test Requirements

**This is what makes Ralph work.** Without proper backpressure, Ralph produces untested, unreliable code.

### The Backpressure Principle

```
Specs (WHAT success looks like)
    ↓ derive
Test Requirements (WHAT to verify)
    ↓ implement
Tests (binary pass/fail)
    ↓ enforce
Implementation (HOW to achieve it)
```

**Key insight:** Tests verify **WHAT** works, not **HOW** it's implemented. Implementation approach is up to Ralph; verification criteria are not.

### Acceptance-Driven Test Derivation

During **planning**, each task must include derived test requirements:

```markdown
## Task: Network Magic Bytes

- [ ] Change `pchMessageStart` to `{0xB0, 0x7C, 0x01, 0x0E}`

**Required Tests (from acceptance criteria):**
- Test: Botcoin node rejects Bitcoin network magic (0xf9beb4d9)
- Test: Botcoin node accepts Botcoin network magic (0xB07C010E)
- Test: Bitcoin node rejects Botcoin network magic
```

### No Cheating Rule

**A task is NOT complete until:**
1. All required tests exist
2. All required tests pass
3. Changes are committed

You cannot claim done without tests passing. Tests are **part of implementation scope**, not optional.

### Test Categories

| Category | Validates | Example |
|----------|-----------|---------|
| **Unit** | Single function behavior | `RandomXHash(input) == expected` |
| **Functional** | End-to-end behavior | Node mines block, other node accepts it |
| **Integration** | Component interaction | Wallet creates address with correct prefix |
| **Regression** | No breakage | Existing tests still pass |

### Implementation Plan Format

Each task MUST include:

```markdown
### 1.2 Create RandomX Hash Wrapper
- [ ] Create `src/crypto/randomx_hash.cpp`
- [ ] Implement `RandomXHash(data, seed) -> uint256`

**Required Tests:**
```cpp
// Unit test: Known hash vector
BOOST_AUTO_TEST_CASE(randomx_known_hash) {
    auto result = RandomXHash(known_input, known_seed);
    BOOST_CHECK_EQUAL(result.GetHex(), "expected_hash");
}

// Unit test: Determinism
BOOST_AUTO_TEST_CASE(randomx_deterministic) {
    auto h1 = RandomXHash(input, seed);
    auto h2 = RandomXHash(input, seed);
    BOOST_CHECK_EQUAL(h1, h2);
}
```

**Acceptance Criteria (from spec):**
- Hash matches RandomX reference implementation
- Same input always produces same output
```

---

## Steering Ralph

### Upstream Steering (Inputs)

- **Specs with acceptance criteria** — Clear success conditions
- **Existing code patterns** — Ralph discovers and follows them
- **`AGENTS.md`** — Operational commands, build/test instructions

### Downstream Steering (Backpressure)

- **Tests** — Derived from acceptance criteria, binary pass/fail
- **Build** — Must compile
- **Type checks** — Compiler catches type errors
- **Lints** — Style enforcement

**`AGENTS.md` specifies the actual commands:**

```markdown
## Validation Commands

- Build: `cmake --build build`
- Unit tests: `ctest --test-dir build`
- Functional tests: `./test/functional/test_runner.py`
- Specific test: `./test/functional/feature_randomx.py`
```

### When Things Go Wrong

| Symptom | Solution |
|---------|----------|
| Ralph goes in circles | Regenerate plan |
| Tests not running | Update `AGENTS.md` with correct commands |
| Wrong patterns | Add utilities/patterns for Ralph to discover |
| Missing tests | Add to plan with explicit test requirements |
| Task claimed done but broken | Add failing test, mark task incomplete |

---

## Files

```
project-root/
├── loopclaude.sh           # Build/plan loop
├── PROMPT_plan.md          # Planning mode instructions
├── PROMPT_build.md         # Building mode instructions  
├── AGENTS.md               # Operational guide (~60 lines max)
├── IMPLEMENTATION_PLAN.md  # Tasks with test requirements
├── specs/                  # Requirement specs with acceptance criteria
│   ├── consensus.md
│   └── ...
└── src/                    # Source code
```

### `AGENTS.md`

Operational only. Contains:
- Build commands
- Test commands
- Validation commands
- Codebase patterns

**NOT** a changelog. Status belongs in `IMPLEMENTATION_PLAN.md`.

### `IMPLEMENTATION_PLAN.md`

Prioritized task list with test requirements. Ralph manages this file.

```markdown
## Phase 1: RandomX Integration

### 1.1 Add RandomX Library
- [ ] Add as git submodule
- [ ] Update CMakeLists.txt

**Required Tests:**
- Build succeeds with RandomX linked
- `randomx_get_flags()` symbol exists

### 1.2 RandomX Hash Wrapper  
- [ ] Create randomx_hash.cpp
...
```

**Plan is disposable** — If wrong, regenerate. One planning loop is cheap.

---

## Acceptance Criteria → Test Requirements Flow

### In Specs (Phase 1)

```markdown
# specs/addresses.md

## Acceptance Criteria

1. P2PKH addresses start with 'B'
2. P2SH addresses start with 'A'
3. Bech32 addresses start with 'bot1'
4. Bitcoin addresses are rejected as invalid
```

### In Plan (Phase 2)

```markdown
### Task: Address Prefixes

- [ ] Set PUBKEY_ADDRESS = 25
- [ ] Set SCRIPT_ADDRESS = 5
- [ ] Set bech32_hrp = "bot"

**Required Tests (derived from acceptance criteria):**

```python
def test_p2pkh_prefix(self):
    addr = self.nodes[0].getnewaddress("", "legacy")
    assert addr.startswith('B')

def test_p2sh_prefix(self):
    addr = self.nodes[0].getnewaddress("", "p2sh-segwit")
    assert addr.startswith('A')

def test_bech32_prefix(self):
    addr = self.nodes[0].getnewaddress("", "bech32")
    assert addr.startswith('bot1')

def test_bitcoin_rejected(self):
    result = self.nodes[0].validateaddress("1BvBMSEY...")
    assert not result['isvalid']
```
```

### In Code (Phase 3)

Ralph implements both the code change AND the tests. Task not done until tests pass.

---

## Summary: The Ralph Contract

1. **Specs define WHAT** — Behavioral outcomes, acceptance criteria
2. **Plan derives TESTS** — From acceptance criteria, before implementation
3. **Build implements ALL** — Code + tests, together
4. **Tests enforce DONE** — Can't commit without passing
5. **Loop provides ITERATION** — Eventual consistency through repetition

**No tests = No done. Tests verify WHAT, not HOW.**

---

*Based on [The Ralph Playbook](https://github.com/ClaytonFarr/ralph-playbook) by Clayton Farr and [original Ralph methodology](https://ghuntley.com/ralph/) by Geoffrey Huntley.*
