# Bothereum Specification Index

> EVM-compatible blockchain with RandomX CPU mining for AI agents.
> "Smart contracts, dumb ASICs."

## Implementation Status

| Phase | Spec | Status |
|-------|------|--------|
| **Phase 1** | RandomX Consensus | 📝 Ready |
| **Phase 2** | Network Parameters | 📝 Ready |
| **Phase 3** | Branding & CLI | 📝 Ready |
| **Phase 4** | Build & Test | 📝 Ready |
| **Phase 5** | Deployment | ⏳ Pending |
| **Phase 6** | Smart Contracts | 📝 Ready |

## Core Specifications

| Specification | File | Description |
|--------------|------|-------------|
| **Implementation Plan** | [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) | Master build guide |
| **Network** | [network.md](network.md) | Ports, chain ID, network params |
| **Consensus** | [consensus.md](consensus.md) | RandomX PoW, block time |
| **Branding** | [branding.md](branding.md) | Binary names, data directories |
| **EVM Compatibility** | [evm.md](evm.md) | Base/Ethereum compatibility |

## Smart Contract Specifications

| Specification | File | Description |
|--------------|------|-------------|
| **Casino Contracts** | [casino-contracts.md](casino-contracts.md) | Zero-edge roulette, wBOT |
| **Staking Contracts** | [staking-contracts.md](staking-contracts.md) | sBOT, yield distribution |

## Key Differentiators from Ethereum Classic

| Feature | ETC | Bothereum | Rationale |
|---------|-----|----------|-----------|
| PoW Algorithm | Ethash (GPU) | RandomX (CPU) | Agent-mineable |
| Block Time | 13 seconds | 60 seconds | Match Botcoin/Bonero |
| Chain ID | 61 | 8061 | Network separation |
| P2P Port | 30303 | 30803 | Network separation |
| Binary | geth | both | Distinct identity |

## EVM Compatibility Goals

**Maximum compatibility with:**
- Base contracts
- Ethereum mainnet contracts
- Arbitrum/Optimism contracts
- All ERC standards (20, 721, 1155, etc.)
- Solidity/Vyper tooling
- Hardhat, Foundry, Remix

**What stays identical:**
- EVM opcodes and gas costs
- Contract ABI encoding
- RPC API (eth_*)
- Transaction format

**What changes:**
- Consensus algorithm only
- Block time
- Network identifiers

## Contract Addresses (Mainnet - TBD)

| Contract | Address |
|----------|---------|
| wBOT | TBD |
| sBOT | TBD |
| StakingManager | TBD |
| ZeroEdgeRoulette | TBD |
| Governor | TBD |

## Quick Start

```bash
# Clone
git clone https://github.com/happybigmtn/bothereum.git
cd bothereum

# Build
go build -o build/bin/both ./cmd/geth

# Run devnet
./build/bin/both --dev --http --http.port 8645

# Run mainnet
./build/bin/both --datadir ~/.bothereum --http
```

## Related Repositories

| Chain | Repo | Purpose |
|-------|------|---------|
| Botcoin | github.com/happybigmtn/botcoin | L1 value transfer |
| **Bothereum** | github.com/happybigmtn/bothereum | EVM contracts |
| Bonero | github.com/happybigmtn/bonero | Privacy |
| Botcash | github.com/happybigmtn/botcash | Messaging |
| Botchan | github.com/happybigmtn/botchan | Cross-chain |

---

*Build the EVM layer for the agent economy.*
