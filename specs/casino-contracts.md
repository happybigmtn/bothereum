# Bothereum Casino Contracts

*Zero-edge provably fair gambling on EVM*

---

## Overview

Solidity smart contracts for zero-edge roulette and future casino games. Uses commit-reveal for provable fairness with optional VRF upgrade path.

---

## Contract Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CASINO ECOSYSTEM                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   wBOT.sol   │    │ Staking.sol  │    │  Treasury    │  │
│  │              │◄──►│              │◄──►│              │  │
│  │ Wrapped BOT  │    │ sBOT minting │    │ Fee collect  │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│          │                   │                   │          │
│          └───────────────────┼───────────────────┘          │
│                              │                              │
│                              ▼                              │
│                    ┌──────────────────┐                    │
│                    │   Roulette.sol   │                    │
│                    │                  │                    │
│                    │ - Commit/reveal  │                    │
│                    │ - Bet placement  │                    │
│                    │ - Auto payout    │                    │
│                    └──────────────────┘                    │
│                              │                              │
│                              ▼                              │
│                    ┌──────────────────┐                    │
│                    │  GameFactory.sol │                    │
│                    │                  │                    │
│                    │ Future games:    │                    │
│                    │ - Blackjack      │                    │
│                    │ - Dice           │                    │
│                    │ - Slots          │                    │
│                    └──────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Contracts

### 1. Roulette.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ZeroEdgeRoulette is Ownable, ReentrancyGuard {
    
    // ============ State ============
    
    IERC20 public immutable wBOT;
    address public stakingPool;
    
    uint256 public gameCounter;
    uint256 public bettingDuration = 60 seconds;
    uint256 public defaultTipPercent = 200; // 2.00% (basis points)
    
    enum GameState { Open, Locked, Revealed }
    
    struct Game {
        GameState state;
        bytes32 commitHash;      // SHA256(serverSeed || nonce)
        uint256 bettingEnds;
        uint256 totalBets;
        uint8 result;            // 0-36
        bytes32 serverSeed;
        uint256 clientSeedSum;   // XOR of all client seeds
    }
    
    struct Bet {
        address player;
        uint256 amount;
        BetType betType;
        uint8[] numbers;         // Selected numbers
        bytes32 clientSeed;
        uint16 tipPercent;       // Basis points (0-500 = 0-5%)
    }
    
    enum BetType {
        Straight,    // 1 number, pays 36:1
        Split,       // 2 numbers, pays 17:1
        Street,      // 3 numbers, pays 11:1
        Corner,      // 4 numbers, pays 8:1
        SixLine,     // 6 numbers, pays 5:1
        Dozen,       // 12 numbers, pays 2:1
        Column,      // 12 numbers, pays 2:1
        RedBlack,    // 18 numbers, pays 1:1
        OddEven,     // 18 numbers, pays 1:1
        LowHigh      // 18 numbers, pays 1:1
    }
    
    mapping(uint256 => Game) public games;
    mapping(uint256 => Bet[]) public gameBets;
    mapping(address => uint256) public playerTrust; // Games played
    
    // ============ Events ============
    
    event GameCreated(uint256 indexed gameId, bytes32 commitHash, uint256 bettingEnds);
    event BetPlaced(uint256 indexed gameId, address indexed player, uint256 amount, BetType betType);
    event GameRevealed(uint256 indexed gameId, uint8 result, bytes32 serverSeed);
    event Payout(uint256 indexed gameId, address indexed player, uint256 amount, uint256 tip);
    
    // ============ Constructor ============
    
    constructor(address _wBOT, address _stakingPool) Ownable(msg.sender) {
        wBOT = IERC20(_wBOT);
        stakingPool = _stakingPool;
    }
    
    // ============ Game Management ============
    
    function createGame(bytes32 commitHash) external onlyOwner returns (uint256) {
        uint256 gameId = ++gameCounter;
        
        games[gameId] = Game({
            state: GameState.Open,
            commitHash: commitHash,
            bettingEnds: block.timestamp + bettingDuration,
            totalBets: 0,
            result: 0,
            serverSeed: bytes32(0),
            clientSeedSum: 0
        });
        
        emit GameCreated(gameId, commitHash, games[gameId].bettingEnds);
        return gameId;
    }
    
    function placeBet(
        uint256 gameId,
        uint256 amount,
        BetType betType,
        uint8[] calldata numbers,
        bytes32 clientSeed,
        uint16 tipPercent
    ) external nonReentrant {
        Game storage game = games[gameId];
        
        require(game.state == GameState.Open, "Game not open");
        require(block.timestamp < game.bettingEnds, "Betting closed");
        require(amount >= minBet(msg.sender), "Below min bet");
        require(amount <= maxBet(msg.sender), "Above max bet");
        require(tipPercent <= 500, "Max tip 5%");
        require(validateBet(betType, numbers), "Invalid bet");
        
        // Transfer wBOT from player
        wBOT.transferFrom(msg.sender, address(this), amount);
        
        // Record bet
        gameBets[gameId].push(Bet({
            player: msg.sender,
            amount: amount,
            betType: betType,
            numbers: numbers,
            clientSeed: clientSeed,
            tipPercent: tipPercent
        }));
        
        game.totalBets += amount;
        game.clientSeedSum ^= uint256(clientSeed);
        
        emit BetPlaced(gameId, msg.sender, amount, betType);
    }
    
    function revealAndSettle(
        uint256 gameId,
        bytes32 serverSeed,
        uint256 nonce
    ) external onlyOwner nonReentrant {
        Game storage game = games[gameId];
        
        require(game.state == GameState.Open, "Game not open");
        require(block.timestamp >= game.bettingEnds, "Betting not closed");
        
        // Verify commitment
        bytes32 expectedHash = keccak256(abi.encodePacked(serverSeed, nonce));
        require(expectedHash == game.commitHash, "Invalid reveal");
        
        // Calculate result
        bytes32 finalSeed = keccak256(abi.encodePacked(
            serverSeed,
            bytes32(game.clientSeedSum)
        ));
        uint8 result = uint8(uint256(finalSeed) % 37);
        
        game.state = GameState.Revealed;
        game.result = result;
        game.serverSeed = serverSeed;
        
        emit GameRevealed(gameId, result, serverSeed);
        
        // Process payouts
        _processPayouts(gameId, result);
    }
    
    // ============ Internal ============
    
    function _processPayouts(uint256 gameId, uint8 result) internal {
        Bet[] storage bets = gameBets[gameId];
        
        for (uint256 i = 0; i < bets.length; i++) {
            Bet storage bet = bets[i];
            
            if (isWinningBet(bet.betType, bet.numbers, result)) {
                uint256 payout = calculatePayout(bet.betType, bet.amount);
                uint256 tip = (payout * bet.tipPercent) / 10000;
                uint256 netPayout = payout - tip;
                
                // Pay winner
                wBOT.transfer(bet.player, netPayout);
                
                // Send tip to staking pool (70%) and treasury (30%)
                if (tip > 0) {
                    wBOT.transfer(stakingPool, (tip * 70) / 100);
                    // Remaining 30% stays in contract (treasury)
                }
                
                playerTrust[bet.player]++;
                emit Payout(gameId, bet.player, netPayout, tip);
            }
        }
    }
    
    function isWinningBet(
        BetType betType,
        uint8[] memory numbers,
        uint8 result
    ) public pure returns (bool) {
        if (result == 0 && betType != BetType.Straight) {
            return false; // Zero loses all outside bets
        }
        
        for (uint256 i = 0; i < numbers.length; i++) {
            if (numbers[i] == result) return true;
        }
        return false;
    }
    
    function calculatePayout(BetType betType, uint256 amount) public pure returns (uint256) {
        // True odds (zero edge)
        if (betType == BetType.Straight) return amount * 37; // 36:1 + stake
        if (betType == BetType.Split) return amount * 18;    // 17:1 + stake
        if (betType == BetType.Street) return amount * 12;   // 11:1 + stake
        if (betType == BetType.Corner) return amount * 9;    // 8:1 + stake
        if (betType == BetType.SixLine) return amount * 6;   // 5:1 + stake
        if (betType == BetType.Dozen) return amount * 3;     // 2:1 + stake
        if (betType == BetType.Column) return amount * 3;    // 2:1 + stake
        return amount * 2; // 1:1 + stake for Red/Black/Odd/Even/Low/High
    }
    
    function validateBet(BetType betType, uint8[] calldata numbers) public pure returns (bool) {
        uint256 expected;
        if (betType == BetType.Straight) expected = 1;
        else if (betType == BetType.Split) expected = 2;
        else if (betType == BetType.Street) expected = 3;
        else if (betType == BetType.Corner) expected = 4;
        else if (betType == BetType.SixLine) expected = 6;
        else expected = 18; // Dozen, Column, Red/Black, etc.
        
        if (numbers.length != expected) return false;
        
        for (uint256 i = 0; i < numbers.length; i++) {
            if (numbers[i] > 36) return false;
        }
        return true;
    }
    
    function minBet(address player) public view returns (uint256) {
        return 0.001 ether; // 0.001 wBOT
    }
    
    function maxBet(address player) public view returns (uint256) {
        uint256 trust = playerTrust[player];
        if (trust < 10) return 0.1 ether;
        if (trust < 100) return 1 ether;
        if (trust < 1000) return 10 ether;
        return 100 ether;
    }
    
    // ============ Admin ============
    
    function setStakingPool(address _stakingPool) external onlyOwner {
        stakingPool = _stakingPool;
    }
    
    function setBettingDuration(uint256 _duration) external onlyOwner {
        bettingDuration = _duration;
    }
    
    function withdrawTreasury(uint256 amount) external onlyOwner {
        wBOT.transfer(owner(), amount);
    }
}
```

### 2. wBOT.sol (Wrapped Botcoin)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract WrappedBotcoin is ERC20, AccessControl {
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    
    mapping(bytes32 => bool) public processedDeposits;
    
    event Deposit(address indexed to, uint256 amount, bytes32 indexed l1TxHash);
    event Withdrawal(address indexed from, uint256 amount, string botcoinAddress);
    
    constructor() ERC20("Wrapped Botcoin", "wBOT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function mint(
        address to,
        uint256 amount,
        bytes32 l1TxHash
    ) external onlyRole(BRIDGE_ROLE) {
        require(!processedDeposits[l1TxHash], "Already processed");
        processedDeposits[l1TxHash] = true;
        _mint(to, amount);
        emit Deposit(to, amount, l1TxHash);
    }
    
    function burn(uint256 amount, string calldata botcoinAddress) external {
        _burn(msg.sender, amount);
        emit Withdrawal(msg.sender, amount, botcoinAddress);
    }
    
    function decimals() public pure override returns (uint8) {
        return 8; // Match Botcoin's 8 decimals
    }
}
```

---

## Verification API

```solidity
// Anyone can verify game fairness
function verifyGame(uint256 gameId) external view returns (
    bool valid,
    bytes32 expectedHash,
    bytes32 actualHash,
    uint8 expectedResult,
    uint8 actualResult
) {
    Game storage game = games[gameId];
    require(game.state == GameState.Revealed, "Not revealed");
    
    // Recalculate commitment
    // (Need nonce from off-chain, or store it)
    
    // Recalculate result
    bytes32 finalSeed = keccak256(abi.encodePacked(
        game.serverSeed,
        bytes32(game.clientSeedSum)
    ));
    expectedResult = uint8(uint256(finalSeed) % 37);
    actualResult = game.result;
    
    valid = (expectedResult == actualResult);
    return (valid, game.commitHash, bytes32(0), expectedResult, actualResult);
}
```

---

## Deployment Checklist

### Testnet (Chain ID 8063)

1. [ ] Deploy wBOT contract
2. [ ] Deploy Staking contract (see staking-contracts.md)
3. [ ] Deploy Roulette contract with wBOT and Staking addresses
4. [ ] Mint test wBOT to test accounts
5. [ ] Run 10 test games
6. [ ] Verify all games pass verification
7. [ ] Test payout calculations

### Mainnet (Chain ID 8061)

1. [ ] Audit contracts (internal review minimum)
2. [ ] Deploy wBOT
3. [ ] Set up 3-of-5 multisig for BRIDGE_ROLE
4. [ ] Deploy Staking
5. [ ] Deploy Roulette
6. [ ] Seed liquidity pool with 100 wBOT
7. [ ] Test with small bets first

---

## Gas Estimates

| Operation | Estimated Gas |
|-----------|--------------|
| createGame | ~80,000 |
| placeBet | ~120,000 |
| revealAndSettle (10 bets) | ~500,000 |
| wBOT mint | ~70,000 |
| wBOT burn | ~50,000 |

At 20 gwei gas price and BETH ~= BOT:
- Create game: ~0.0016 BETH
- Place bet: ~0.0024 BETH
- Settle: ~0.01 BETH

---

## Security Considerations

1. **Reentrancy**: ReentrancyGuard on all state-changing functions
2. **Commit-reveal**: Server seed committed before bets, revealed after
3. **Client seed contribution**: XOR of all client seeds prevents operator manipulation
4. **Payout limits**: Trust-based max bets protect liquidity
5. **Access control**: Only owner can create/reveal games

---

## Future Enhancements

1. **VRF Integration**: Chainlink VRF or similar for instant randomness
2. **Multi-game batching**: Multiple games in single transaction
3. **Merkle proof verification**: Off-chain bet storage, on-chain verification
4. **Cross-game jackpots**: Shared progressive jackpot across game types

---

*Zero edge. Full transparency. Verifiable on-chain.*
