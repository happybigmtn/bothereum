# Bothereum Implementation Plan

*From Core-Geth fork to agent-mineable EVM chain*

---

## Current State

- **Base**: Core-Geth v1.12.20 (ETC client, Go implementation)
- **Repo**: github.com/happybigmtn/bothereum
- **Status**: Forked, basic branding done, consensus unchanged

## Target State

Fully functional RandomX-powered EVM chain ready for:
- Agent mining (CPU-friendly)
- Casino contracts (zero-edge roulette)
- Staking contracts (sBOT/wBOT)
- Bridge to Botcoin L1

---

## Phase 1: RandomX Consensus (AC-1)

**Goal**: Replace Ethash with RandomX

### AC-1.1: Add RandomX Dependency

```go
// go.mod addition
require github.com/tevador/RandomX v1.2.1
```

**Files**:
- `go.mod` - Add RandomX Go bindings
- `go.sum` - Update checksums

### AC-1.2: Create RandomX Consensus Engine

**New files**:
```
consensus/randomx/
├── consensus.go     # Engine interface implementation
├── algorithm.go     # RandomX hash computation
├── sealer.go        # Mining/sealing logic
├── difficulty.go    # Difficulty adjustment
└── randomx_test.go  # Unit tests
```

**Key interfaces to implement**:
```go
type Engine interface {
    Author(header *types.Header) (common.Address, error)
    VerifyHeader(chain ChainHeaderReader, header *types.Header) error
    VerifyHeaders(chain ChainHeaderReader, headers []*types.Header) (chan<- struct{}, <-chan error)
    VerifyUncles(chain ChainReader, block *types.Block) error
    Prepare(chain ChainHeaderReader, header *types.Header) error
    Finalize(chain ChainHeaderReader, header *types.Header, state *state.StateDB, body *types.Body)
    FinalizeAndAssemble(chain ChainHeaderReader, header *types.Header, state *state.StateDB, body *types.Body, receipts []*types.Receipt) (*types.Block, error)
    Seal(chain ChainHeaderReader, block *types.Block, results chan<- *types.Block, stop <-chan struct{}) error
    SealHash(header *types.Header) common.Hash
    CalcDifficulty(chain ChainHeaderReader, time uint64, parent *types.Header) *big.Int
    Close() error
}
```

### AC-1.3: RandomX Configuration

```go
// consensus/randomx/config.go
const (
    RandomXArgonSalt    = "BothereumX\x01"  // Unique salt
    RandomXSeedRotation = 2048              // Blocks between seed changes
    RandomXSeedLag      = 64                // Blocks delay for seed switch
    TargetBlockTime     = 60                // Seconds
)
```

### AC-1.4: Difficulty Adjustment

```go
// Per-block adjustment targeting 60s blocks
func CalcDifficulty(time uint64, parent *types.Header) *big.Int {
    // Exponential moving average
    // If block too fast: increase difficulty
    // If block too slow: decrease difficulty
    // Bounded to prevent wild swings
}
```

### AC-1.5: Wire Up Consensus Engine

**Files to modify**:
- `eth/ethconfig/config.go` - Add RandomX config
- `eth/backend.go` - Initialize RandomX engine
- `cmd/geth/config.go` - CLI flags for RandomX
- `params/config.go` - Chain config for RandomX

### AC-1.6: Tests

- Unit tests for RandomX hash verification
- Unit tests for difficulty adjustment
- Integration test: mine 10 blocks on devnet

**Acceptance**: `go test ./consensus/randomx/...` passes

---

## Phase 2: Network Parameters (AC-2)

### AC-2.1: Chain ID & Network

**File**: `params/config.go`

```go
var BothereumChainConfig = &ChainConfig{
    ChainID:             big.NewInt(8061),
    HomesteadBlock:      big.NewInt(0),
    EIP150Block:         big.NewInt(0),
    EIP155Block:         big.NewInt(0),
    EIP158Block:         big.NewInt(0),
    ByzantiumBlock:      big.NewInt(0),
    ConstantinopleBlock: big.NewInt(0),
    PetersburgBlock:     big.NewInt(0),
    IstanbulBlock:       big.NewInt(0),
    BerlinBlock:         big.NewInt(0),
    LondonBlock:         big.NewInt(0),
    RandomX:             &RandomXConfig{},
}
```

### AC-2.2: Genesis Block

**File**: `core/genesis_bothereum.go`

```go
func DefaultBothereumGenesisBlock() *Genesis {
    return &Genesis{
        Config:     params.BothereumChainConfig,
        Nonce:      0x0,
        Timestamp:  0x65B8E800,  // Launch timestamp
        ExtraData:  []byte("01100110 01110010 01100101 01100101"), // "free"
        GasLimit:   30000000,
        Difficulty: big.NewInt(1),  // Start easy
        Alloc:      map[common.Address]GenesisAccount{},
    }
}
```

### AC-2.3: Ports & Networking

**File**: `params/bootnodes.go`

```go
var BothereumBootnodes = []string{
    // Add bootstrap nodes after deployment
}

const (
    BothereumP2PPort   = 30803
    BothereumRPCPort   = 8645
    BothereumWSPort    = 8646
)
```

### AC-2.4: Block Rewards

**File**: `consensus/randomx/rewards.go`

```go
var (
    BlockReward       = big.NewInt(2.5e18)  // 2.5 BETH
    ReductionInterval = uint64(5_000_000)   // Every 5M blocks
    ReductionPercent  = 20                  // 20% reduction
)
```

**Acceptance**: Genesis block generates with correct parameters

---

## Phase 3: Branding & CLI (AC-3)

### AC-3.1: Binary Names

| Original | Bothereum |
|----------|-----------|
| geth | both |
| geth attach | both attach |
| geth console | both console |

**Files**: `cmd/geth/` → `cmd/both/`

### AC-3.2: Data Directory

- Linux: `~/.bothereum/`
- macOS: `~/Library/Bothereum/`
- Windows: `%APPDATA%\Bothereum\`

### AC-3.3: User Agent

```go
const ClientIdentifier = "Bothereum"
const VersionMajor = 1
const VersionMinor = 0
const VersionPatch = 0
```

### AC-3.4: Config File

Default config: `bothereum.toml`

**Acceptance**: `both version` shows "Bothereum/v1.0.0"

---

## Phase 4: Build & Test (AC-4)

### AC-4.1: Build Script

```bash
#!/bin/bash
# build.sh
set -e

echo "Building Bothereum..."
go build -o build/bin/both ./cmd/both
go build -o build/bin/both-clef ./cmd/clef
go build -o build/bin/both-devp2p ./cmd/devp2p
go build -o build/bin/both-abigen ./cmd/abigen

echo "Build complete!"
ls -la build/bin/
```

### AC-4.2: Test Suite

```bash
# Run all tests
go test ./...

# Run consensus tests specifically
go test ./consensus/randomx/... -v

# Integration test
./scripts/test-devnet.sh
```

### AC-4.3: Devnet Script

```bash
#!/bin/bash
# scripts/test-devnet.sh

# Initialize
./build/bin/both init --datadir /tmp/both-test genesis.json

# Start node
./build/bin/both \
    --datadir /tmp/both-test \
    --networkid 8061 \
    --http \
    --http.port 8645 \
    --mine \
    --miner.threads 1 \
    --verbosity 4

# Should mine blocks with RandomX
```

**Acceptance**: Devnet mines 10+ blocks successfully

---

## Phase 5: Deployment (AC-5)

### AC-5.1: Build on Contabo Fleet

Deploy to existing mining nodes:
- 95.111.227.14 (node1)
- 95.111.229.108 (node2)
- ... (8 more)

### AC-5.2: Bootstrap Network

1. Start node1 as bootnode
2. Connect remaining nodes
3. Verify peer connections
4. Begin mining

### AC-5.3: Monitoring

- Block explorer (blockscout or similar)
- Grafana dashboard
- Alert on chain halt

**Acceptance**: 10-node network mining, 100+ blocks produced

---

## Phase 6: Smart Contracts (AC-6)

### AC-6.1: wBOT Bridge Contract

Wrapped Botcoin on Bothereum:

```solidity
// contracts/wBOT.sol
contract WrappedBotcoin is ERC20, Ownable {
    mapping(bytes32 => bool) public processedDeposits;
    
    function mint(address to, uint256 amount, bytes32 txHash) external onlyBridge {
        require(!processedDeposits[txHash], "Already processed");
        processedDeposits[txHash] = true;
        _mint(to, amount);
    }
    
    function burn(uint256 amount, string calldata botcoinAddress) external {
        _burn(msg.sender, amount);
        emit BurnForWithdrawal(msg.sender, amount, botcoinAddress);
    }
}
```

### AC-6.2: Casino Contract

See `specs/casino-contracts.md`

### AC-6.3: Staking Contract

See `specs/staking-contracts.md`

**Acceptance**: All contracts deployed on testnet, basic integration tests pass

---

## Implementation Order

```
Week 1: AC-1 (RandomX consensus)
Week 2: AC-2 + AC-3 (Network + Branding)
Week 3: AC-4 (Build + Test)
Week 4: AC-5 (Deployment)
Week 5-6: AC-6 (Smart contracts)
```

---

## Success Criteria

- [ ] RandomX mining works (CPU only, no GPU advantage)
- [ ] 60-second block times achieved
- [ ] 10+ node network operational
- [ ] EVM fully compatible (deploy Uniswap V2 as test)
- [ ] wBOT bridge functional
- [ ] Casino contract deployed
- [ ] Staking contract deployed

---

## Key Files Reference

| Component | Primary File |
|-----------|-------------|
| RandomX engine | `consensus/randomx/consensus.go` |
| Chain config | `params/config.go` |
| Genesis | `core/genesis_bothereum.go` |
| CLI | `cmd/both/main.go` |
| Networking | `p2p/server.go` |

---

*Build the EVM layer for the agent economy.*
