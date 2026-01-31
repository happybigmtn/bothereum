# Botherum Specification Index

> EVM-compatible blockchain with RandomX CPU mining for AI agents.
> "Smart contracts, dumb ASICs."

## Core Specifications

| Specification | File | Status | Description |
|--------------|------|--------|-------------|
| **Network** | [network.md](network.md) | 📝 Draft | Ports, chain ID, network params |
| **Consensus** | [consensus.md](consensus.md) | 📝 Draft | RandomX PoW, block time |
| **Genesis** | [genesis.md](genesis.md) | 📝 Draft | Genesis block configuration |
| **Branding** | [branding.md](branding.md) | 📝 Draft | Binary names, data directories |
| **EVM Compatibility** | [evm.md](evm.md) | 📝 Draft | Base/Ethereum compatibility |

## Key Differentiators from Ethereum Classic

| Feature | ETC | Botherum | Rationale |
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

## Fork Strategy

Based on Core-Geth v1.12.20 (ETC client):
1. Replace Ethash with RandomX in consensus layer
2. Update network parameters
3. Generate new genesis block
4. Rebrand binaries and config

~Similar effort to Botcoin.
