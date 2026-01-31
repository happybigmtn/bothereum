# Bothereum Consensus

## Proof of Work: RandomX

Replace Ethash with RandomX for CPU-friendly mining.

| Parameter | ETC (Ethash) | Bothereum (RandomX) |
|-----------|--------------|---------------------|
| Algorithm | Ethash | RandomX |
| Hardware | GPU/ASIC | CPU |
| Dataset | DAG (4GB+) | 2GB dataset |
| Block time | 13 seconds | 60 seconds |
| Difficulty adjustment | Per block | Per block |

## Block Time: 60 seconds

Match Botcoin and Bonero for consistent agent mining experience.

| Parameter | Value |
|-----------|-------|
| Target block time | 60 seconds |
| Difficulty adjustment | Every block |
| Uncle rate target | ~5% |

## Block Reward

| Parameter | Value |
|-----------|-------|
| Initial reward | 2.5 BOTH |
| Reduction | 20% every 5M blocks |
| Uncle reward | 7/8 of block reward |

## Implementation

Files to modify:
- `consensus/ethash/` → `consensus/randomx/`
- Add RandomX library as dependency
- Update block validation
- Update mining code
