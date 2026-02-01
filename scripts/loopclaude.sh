#!/bin/bash
# loopclaude.sh - Run Claude Code in a loop for Bothereum implementation
#
# Usage: ./scripts/loopclaude.sh [phase]
# 
# Runs Claude Code repeatedly, working through the implementation plan.
# Each iteration picks up where the last left off.

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Default to phase 1 if not specified
PHASE="${1:-1}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Bothereum Implementation Loop - Phase $PHASE${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"

# Check for claude command
if ! command -v claude &> /dev/null; then
    echo -e "${RED}Error: claude command not found${NC}"
    echo "Install with: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# Phase prompts
get_phase_prompt() {
    case $1 in
        1)
            echo "Work on Phase 1 (AC-1): RandomX Consensus Integration.

Read specs/IMPLEMENTATION_PLAN.md for context.

Tasks:
1. Add RandomX Go bindings to go.mod
2. Create consensus/randomx/ directory structure
3. Implement the Engine interface for RandomX
4. Add RandomX configuration constants

Start with AC-1.1 (add dependency) and AC-1.2 (create consensus engine structure).
Build and test after each change. Commit progress."
            ;;
        2)
            echo "Work on Phase 2 (AC-2): Network Parameters.

Read specs/IMPLEMENTATION_PLAN.md for context.

Tasks:
1. Update params/config.go with BothereumChainConfig
2. Create genesis block configuration
3. Update ports and networking constants
4. Configure block rewards

Build and test after each change. Commit progress."
            ;;
        3)
            echo "Work on Phase 3 (AC-3): Branding & CLI.

Read specs/IMPLEMENTATION_PLAN.md for context.

Tasks:
1. Rename cmd/geth to cmd/both
2. Update data directory paths
3. Update user agent strings
4. Update config file names

Build and test after each change. Commit progress."
            ;;
        4)
            echo "Work on Phase 4 (AC-4): Build & Test.

Read specs/IMPLEMENTATION_PLAN.md for context.

Tasks:
1. Create build script
2. Run test suite, fix any failures
3. Create devnet test script
4. Verify node can mine blocks

Document any issues found."
            ;;
        5)
            echo "Work on Phase 5 (AC-5): Deployment Preparation.

Read specs/IMPLEMENTATION_PLAN.md for context.

Tasks:
1. Create deployment scripts for Contabo nodes
2. Generate genesis block
3. Create systemd service files
4. Document bootstrap process"
            ;;
        6)
            echo "Work on Phase 6 (AC-6): Smart Contracts.

Read specs/casino-contracts.md and specs/staking-contracts.md.

Tasks:
1. Set up Hardhat/Foundry project in contracts/
2. Implement wBOT.sol
3. Implement sBOT.sol  
4. Implement StakingManager.sol
5. Implement ZeroEdgeRoulette.sol
6. Write tests for all contracts

Compile and test after each contract."
            ;;
        *)
            echo "Unknown phase: $1. Valid phases: 1-6"
            exit 1
            ;;
    esac
}

PROMPT=$(get_phase_prompt "$PHASE")

# Iteration counter
ITER=1
MAX_ITERS=10

while [ $ITER -le $MAX_ITERS ]; do
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  Iteration $ITER / $MAX_ITERS${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Run Claude Code
    echo -e "${GREEN}Running Claude Code...${NC}"
    
    # Use --print for non-interactive mode with output
    if claude --print "$PROMPT

Continue from where you left off. Check git status and recent commits to see progress.
If the phase is complete, say 'PHASE_COMPLETE' and summarize what was done.
If you need input, say 'NEED_INPUT: <question>'.
Otherwise, make progress and commit your changes." 2>&1 | tee "/tmp/claude-iter-$ITER.log"; then
        
        # Check for completion signals
        if grep -q "PHASE_COMPLETE" "/tmp/claude-iter-$ITER.log"; then
            echo ""
            echo -e "${GREEN}✓ Phase $PHASE complete!${NC}"
            
            # Auto-advance to next phase
            if [ "$PHASE" -lt 6 ]; then
                NEXT_PHASE=$((PHASE + 1))
                echo -e "${YELLOW}Advancing to Phase $NEXT_PHASE...${NC}"
                PHASE=$NEXT_PHASE
                PROMPT=$(get_phase_prompt "$PHASE")
                ITER=1
                continue
            else
                echo -e "${GREEN}All phases complete!${NC}"
                break
            fi
        fi
        
        if grep -q "NEED_INPUT:" "/tmp/claude-iter-$ITER.log"; then
            echo ""
            echo -e "${YELLOW}Claude needs input. Check the log above.${NC}"
            echo "Press Enter to continue or Ctrl+C to stop..."
            read -r
        fi
    else
        echo -e "${RED}Claude exited with error${NC}"
        echo "Check /tmp/claude-iter-$ITER.log for details"
        exit 1
    fi
    
    ITER=$((ITER + 1))
    
    # Brief pause between iterations
    sleep 2
done

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Loop complete after $ITER iterations${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"

# Show final status
echo ""
echo "Git status:"
git status --short

echo ""
echo "Recent commits:"
git log --oneline -5
