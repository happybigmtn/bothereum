# Bothereum Implementation Plan

> EVM chain with RandomX PoW for AI agents.
> Based on Core-Geth v1.12.20
> **Status**: 0% complete - specs ready

---

## Phase 1: RandomX Integration

### 1.1 Add RandomX Library
- [ ] Add RandomX as Go module dependency
- [ ] Create `consensus/randomx/` package
- [ ] Implement RandomX hasher interface

### 1.2 Replace Ethash
- [ ] Update `consensus/ethash/` to use RandomX
- [ ] Modify block validation for RandomX proofs
- [ ] Update difficulty calculation for 60s target

### 1.3 Mining
- [ ] Update miner to use RandomX
- [ ] Add CPU thread configuration
- [ ] Test mining locally

---

## Phase 2: Network Parameters

### 2.1 Chain ID
- [ ] Set mainnet chain ID to 8061
- [ ] Set testnet chain ID to 8063
- [ ] Update genesis configurations

### 2.2 Ports
- [ ] Set P2P port to 30803
- [ ] Set RPC port to 8645
- [ ] Set WebSocket port to 8646

### 2.3 Block Time
- [ ] Set target block time to 60 seconds
- [ ] Adjust difficulty algorithm

---

## Phase 3: Genesis Block

### 3.1 Genesis Configuration
- [ ] Create Bothereum genesis.json
- [ ] All EIPs active from block 0
- [ ] Initial allocation for development

### 3.2 Genesis Mining
- [ ] Mine genesis block with RandomX
- [ ] Set genesis hash in code

---

## Phase 4: Branding

### 4.1 Binary Names
- [ ] Rename geth → both
- [ ] Update all related binaries
- [ ] Update Makefile targets

### 4.2 Data Directory
- [ ] Change default from .ethereum to .bethereum
- [ ] Update all path references

### 4.3 User Agent
- [ ] Update version strings to Bothereum

---

## Phase 5: Testing

### 5.1 Unit Tests
- [ ] RandomX consensus tests
- [ ] Chain ID / network tests

### 5.2 Integration Tests
- [ ] Full node sync test
- [ ] Mining test
- [ ] Contract deployment test

### 5.3 EVM Compatibility
- [ ] Deploy standard ERC-20
- [ ] Deploy standard ERC-721
- [ ] Test with Hardhat
- [ ] Test with Foundry

---

## Files to Modify

### Consensus
- `consensus/ethash/` - Replace with RandomX
- `core/types/block.go` - Block structure
- `miner/` - Mining logic

### Network
- `params/config.go` - Chain IDs, fork blocks
- `params/bootnodes.go` - Seed nodes
- `cmd/geth/main.go` - Default ports

### Branding
- `Makefile` - Binary names
- `cmd/` - All command entry points
- `internal/` - Version strings
