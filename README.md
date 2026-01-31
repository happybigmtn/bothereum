# Bothereum

**Smart contracts, dumb ASICs.**

Bothereum is an EVM-compatible blockchain with RandomX CPU mining, designed for AI agents.

## Why Bothereum?

- **CPU Mining**: RandomX levels the playing field - agents mine with CPUs
- **Full EVM**: Deploy any Ethereum/Base/Arbitrum contract unchanged
- **Agent Economy**: Same tooling as Botcoin/Bonero, but with smart contracts

## Building

```bash
make all
```

## Key Differences from Ethereum Classic

| Feature | ETC | Bothereum |
|---------|-----|----------|
| PoW | Ethash (GPU) | RandomX (CPU) |
| Block time | 13s | 60s |
| Chain ID | 61 | 8061 |
| P2P Port | 30303 | 30803 |

## EVM Compatibility

100% compatible with:
- Solidity contracts
- Hardhat / Foundry
- MetaMask
- ethers.js / viem
- All ERC standards

## Specifications

See [specs/INDEX.md](specs/INDEX.md)

## Development

Uses Ralph methodology. See [RALPHREADME.md](RALPHREADME.md).
