# AGENTS.md - Bothereum Build Guide

## Overview

Bothereum is an EVM-compatible blockchain with RandomX CPU mining for AI agents.
Based on Core-Geth (Ethereum Classic client).

## Quick Reference

```bash
# Build
go build -o build/bin/both ./cmd/geth

# Test
go test ./...

# Run devnet
./build/bin/both --dev --http --http.port 8645
```

## Implementation Plan

Read `specs/IMPLEMENTATION_PLAN.md` for the full build guide.

### Phases

1. **RandomX Consensus** - Replace Ethash with RandomX
2. **Network Parameters** - Chain ID 8061, ports, genesis
3. **Branding** - Rename geth → both
4. **Build & Test** - Ensure everything compiles and passes
5. **Deployment** - Deploy to Contabo mining fleet
6. **Smart Contracts** - wBOT, sBOT, Casino, Staking

### Current Focus

Check `specs/IMPLEMENTATION_PLAN.md` for current acceptance criteria.

## Key Specifications

| Spec | Description |
|------|-------------|
| `specs/INDEX.md` | Overview and status |
| `specs/IMPLEMENTATION_PLAN.md` | Detailed build guide |
| `specs/consensus.md` | RandomX PoW details |
| `specs/network.md` | Network parameters |
| `specs/casino-contracts.md` | Zero-edge roulette |
| `specs/staking-contracts.md` | sBOT yield system |

## Automated Build Loop

```bash
# Run Claude Code in a loop to implement phases
./scripts/loopclaude.sh 1  # Start with phase 1
```

The loop script:
- Reads the implementation plan
- Works through acceptance criteria
- Commits progress
- Advances to next phase when complete

## Key Files to Modify

| Component | Primary File |
|-----------|-------------|
| RandomX engine | `consensus/randomx/consensus.go` (create) |
| Chain config | `params/config.go` |
| Genesis | `core/genesis.go` |
| CLI | `cmd/geth/main.go` → `cmd/both/main.go` |
| Networking | `p2p/server.go` |

## Dependencies

- Go 1.21+
- RandomX library (github.com/tevador/RandomX)
- Standard Go toolchain

## Network Details

| Parameter | Value |
|-----------|-------|
| Chain ID | 8061 |
| P2P Port | 30803 |
| RPC Port | 8645 |
| WS Port | 8646 |
| Block Time | 60 seconds |
| Block Reward | 2.5 BETH |

## Related Chains

| Chain | Purpose |
|-------|---------|
| Botcoin | L1 value transfer |
| Bothereum | EVM contracts |
| Bonero | Privacy |
| Botcash | Messaging |
| Botchan | Cross-chain swaps |

---

*Build the EVM layer for the agent economy.*
