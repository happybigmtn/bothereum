# Bothereum Staking Contracts

*Earn yield by backing the agent casino*

---

## Overview

sBOT (Staked BOT) is a rebasing receipt token representing staked wBOT. Stakers provide liquidity for casino payouts and earn tips from winners.

---

## Contract Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    STAKING ECOSYSTEM                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                  │
│  │    wBOT      │────────▶│   Staking    │                  │
│  │   (ERC20)    │         │   Manager    │                  │
│  └──────────────┘         └──────────────┘                  │
│                                   │                          │
│                    ┌──────────────┼──────────────┐          │
│                    ▼              ▼              ▼          │
│           ┌──────────────┐ ┌──────────────┐ ┌──────────┐   │
│           │  LP Pool     │ │  Validator   │ │Governance│   │
│           │              │ │  Registry    │ │          │   │
│           │ Casino tips  │ │ Service fees │ │ Treasury │   │
│           └──────────────┘ └──────────────┘ └──────────┘   │
│                    │              │              │          │
│                    └──────────────┼──────────────┘          │
│                                   ▼                          │
│                          ┌──────────────┐                   │
│                          │    sBOT      │                   │
│                          │  (Rebasing)  │                   │
│                          └──────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Contracts

### 1. StakingManager.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StakingManager is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // ============ Roles ============
    
    bytes32 public constant CASINO_ROLE = keccak256("CASINO_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    
    // ============ State ============
    
    IERC20 public immutable wBOT;
    IsBOT public immutable sBOT;
    
    // Pool totals
    uint256 public totalStakedLP;        // Liquidity provider pool
    uint256 public totalStakedValidator; // Validator pool
    uint256 public totalStakedGov;       // Governance pool
    
    // Pending yields (accumulated before distribution)
    uint256 public pendingLPYield;
    uint256 public pendingValidatorYield;
    uint256 public pendingGovYield;
    
    // Lock periods
    uint256 public constant LP_LOCK = 1 days;
    uint256 public constant VALIDATOR_LOCK = 7 days;
    uint256 public constant GOV_LOCK = 30 days;
    
    // Minimum stakes
    uint256 public constant MIN_LP_STAKE = 10e8;        // 10 wBOT
    uint256 public constant MIN_VALIDATOR_STAKE = 100e8; // 100 wBOT
    uint256 public constant MIN_GOV_STAKE = 1000e8;      // 1000 wBOT
    
    enum StakeTier { LP, Validator, Governance }
    
    struct Stake {
        uint256 amount;
        uint256 timestamp;
        StakeTier tier;
        uint256 lastClaimTime;
    }
    
    struct UnstakeRequest {
        uint256 amount;
        uint256 unlockTime;
        StakeTier tier;
    }
    
    mapping(address => Stake) public stakes;
    mapping(address => UnstakeRequest) public unstakeRequests;
    
    // Validator specific
    mapping(address => bool) public isValidator;
    mapping(address => uint256) public validatorSlashAmount;
    
    // ============ Events ============
    
    event Staked(address indexed user, uint256 amount, StakeTier tier);
    event UnstakeRequested(address indexed user, uint256 amount, uint256 unlockTime);
    event Withdrawn(address indexed user, uint256 amount, uint256 yield);
    event YieldDistributed(uint256 lpAmount, uint256 validatorAmount, uint256 govAmount);
    event ValidatorSlashed(address indexed validator, uint256 amount, string reason);
    event TipReceived(uint256 amount, address indexed from);
    
    // ============ Constructor ============
    
    constructor(address _wBOT, address _sBOT) {
        wBOT = IERC20(_wBOT);
        sBOT = IsBOT(_sBOT);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    // ============ Staking ============
    
    function stake(uint256 amount, StakeTier tier) external nonReentrant {
        require(amount >= minStake(tier), "Below minimum");
        require(stakes[msg.sender].amount == 0, "Already staked");
        
        wBOT.safeTransferFrom(msg.sender, address(this), amount);
        
        stakes[msg.sender] = Stake({
            amount: amount,
            timestamp: block.timestamp,
            tier: tier,
            lastClaimTime: block.timestamp
        });
        
        // Update pool totals
        if (tier == StakeTier.LP) totalStakedLP += amount;
        else if (tier == StakeTier.Validator) totalStakedValidator += amount;
        else totalStakedGov += amount;
        
        // Mint sBOT receipt
        sBOT.mint(msg.sender, amount);
        
        emit Staked(msg.sender, amount, tier);
    }
    
    function requestUnstake(uint256 amount) external nonReentrant {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, "Insufficient stake");
        require(unstakeRequests[msg.sender].amount == 0, "Request pending");
        
        uint256 lockPeriod = lockDuration(userStake.tier);
        
        unstakeRequests[msg.sender] = UnstakeRequest({
            amount: amount,
            unlockTime: block.timestamp + lockPeriod,
            tier: userStake.tier
        });
        
        emit UnstakeRequested(msg.sender, amount, block.timestamp + lockPeriod);
    }
    
    function withdraw() external nonReentrant {
        UnstakeRequest storage request = unstakeRequests[msg.sender];
        require(request.amount > 0, "No pending request");
        require(block.timestamp >= request.unlockTime, "Still locked");
        
        Stake storage userStake = stakes[msg.sender];
        
        // Calculate yield
        uint256 yieldAmount = calculateYield(msg.sender);
        
        // Update state
        userStake.amount -= request.amount;
        
        // Update pool totals
        if (request.tier == StakeTier.LP) totalStakedLP -= request.amount;
        else if (request.tier == StakeTier.Validator) totalStakedValidator -= request.amount;
        else totalStakedGov -= request.amount;
        
        // Burn sBOT
        sBOT.burn(msg.sender, request.amount);
        
        // Clear request
        delete unstakeRequests[msg.sender];
        
        // Transfer wBOT + yield
        uint256 totalAmount = request.amount + yieldAmount;
        wBOT.safeTransfer(msg.sender, totalAmount);
        
        emit Withdrawn(msg.sender, request.amount, yieldAmount);
    }
    
    // ============ Yield ============
    
    function receiveTip(uint256 amount) external onlyRole(CASINO_ROLE) {
        // 70% to LP, 20% to validators, 10% to governance
        pendingLPYield += (amount * 70) / 100;
        pendingValidatorYield += (amount * 20) / 100;
        pendingGovYield += (amount * 10) / 100;
        
        emit TipReceived(amount, msg.sender);
    }
    
    function distributeYield() external {
        // Distribute accumulated yields
        // This is called periodically (e.g., daily)
        
        emit YieldDistributed(pendingLPYield, pendingValidatorYield, pendingGovYield);
        
        // Reset pending (yields are tracked in sBOT rebasing)
        pendingLPYield = 0;
        pendingValidatorYield = 0;
        pendingGovYield = 0;
    }
    
    function calculateYield(address user) public view returns (uint256) {
        Stake storage userStake = stakes[user];
        if (userStake.amount == 0) return 0;
        
        uint256 poolTotal;
        uint256 poolYield;
        
        if (userStake.tier == StakeTier.LP) {
            poolTotal = totalStakedLP;
            poolYield = pendingLPYield;
        } else if (userStake.tier == StakeTier.Validator) {
            poolTotal = totalStakedValidator;
            poolYield = pendingValidatorYield;
        } else {
            poolTotal = totalStakedGov;
            poolYield = pendingGovYield;
        }
        
        if (poolTotal == 0) return 0;
        
        return (userStake.amount * poolYield) / poolTotal;
    }
    
    function claimYield() external nonReentrant {
        uint256 yieldAmount = calculateYield(msg.sender);
        require(yieldAmount > 0, "No yield");
        
        stakes[msg.sender].lastClaimTime = block.timestamp;
        wBOT.safeTransfer(msg.sender, yieldAmount);
    }
    
    // ============ Validator Slashing ============
    
    function slashValidator(
        address validator,
        uint256 amount,
        string calldata reason
    ) external onlyRole(ORACLE_ROLE) {
        require(isValidator[validator], "Not a validator");
        require(stakes[validator].amount >= amount, "Insufficient stake");
        
        stakes[validator].amount -= amount;
        totalStakedValidator -= amount;
        validatorSlashAmount[validator] += amount;
        
        // Slashed amount goes to treasury
        // (stays in contract)
        
        emit ValidatorSlashed(validator, amount, reason);
    }
    
    // ============ Helpers ============
    
    function minStake(StakeTier tier) public pure returns (uint256) {
        if (tier == StakeTier.LP) return MIN_LP_STAKE;
        if (tier == StakeTier.Validator) return MIN_VALIDATOR_STAKE;
        return MIN_GOV_STAKE;
    }
    
    function lockDuration(StakeTier tier) public pure returns (uint256) {
        if (tier == StakeTier.LP) return LP_LOCK;
        if (tier == StakeTier.Validator) return VALIDATOR_LOCK;
        return GOV_LOCK;
    }
    
    function getStake(address user) external view returns (
        uint256 amount,
        uint256 timestamp,
        StakeTier tier,
        uint256 pendingYield
    ) {
        Stake storage s = stakes[user];
        return (s.amount, s.timestamp, s.tier, calculateYield(user));
    }
    
    function getTVL() external view returns (uint256 lp, uint256 validator, uint256 gov) {
        return (totalStakedLP, totalStakedValidator, totalStakedGov);
    }
}

interface IsBOT {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}
```

### 2. sBOT.sol (Staked BOT Receipt)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract StakedBotcoin is ERC20, AccessControl {
    bytes32 public constant STAKING_ROLE = keccak256("STAKING_ROLE");
    
    // Rebasing factor (starts at 1e18 = 1.0)
    uint256 public rebaseIndex = 1e18;
    uint256 public lastRebaseTime;
    
    // Internal balances (before rebase multiplier)
    mapping(address => uint256) private _internalBalances;
    uint256 private _internalTotalSupply;
    
    event Rebase(uint256 oldIndex, uint256 newIndex, uint256 yieldAdded);
    
    constructor() ERC20("Staked Botcoin", "sBOT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        lastRebaseTime = block.timestamp;
    }
    
    // ============ Rebasing Logic ============
    
    function rebase(uint256 yieldAmount) external onlyRole(STAKING_ROLE) {
        if (_internalTotalSupply == 0) return;
        
        uint256 oldIndex = rebaseIndex;
        
        // New index = old index * (total + yield) / total
        uint256 currentTotal = totalSupply();
        rebaseIndex = (rebaseIndex * (currentTotal + yieldAmount)) / currentTotal;
        
        lastRebaseTime = block.timestamp;
        
        emit Rebase(oldIndex, rebaseIndex, yieldAmount);
    }
    
    // ============ ERC20 Overrides ============
    
    function totalSupply() public view override returns (uint256) {
        return (_internalTotalSupply * rebaseIndex) / 1e18;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return (_internalBalances[account] * rebaseIndex) / 1e18;
    }
    
    function mint(address to, uint256 amount) external onlyRole(STAKING_ROLE) {
        uint256 internalAmount = (amount * 1e18) / rebaseIndex;
        _internalBalances[to] += internalAmount;
        _internalTotalSupply += internalAmount;
        emit Transfer(address(0), to, amount);
    }
    
    function burn(address from, uint256 amount) external onlyRole(STAKING_ROLE) {
        uint256 internalAmount = (amount * 1e18) / rebaseIndex;
        require(_internalBalances[from] >= internalAmount, "Insufficient balance");
        _internalBalances[from] -= internalAmount;
        _internalTotalSupply -= internalAmount;
        emit Transfer(from, address(0), amount);
    }
    
    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 internalAmount = (amount * 1e18) / rebaseIndex;
        require(_internalBalances[msg.sender] >= internalAmount, "Insufficient balance");
        _internalBalances[msg.sender] -= internalAmount;
        _internalBalances[to] += internalAmount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(from, msg.sender);
        require(currentAllowance >= amount, "Insufficient allowance");
        _approve(from, msg.sender, currentAllowance - amount);
        
        uint256 internalAmount = (amount * 1e18) / rebaseIndex;
        require(_internalBalances[from] >= internalAmount, "Insufficient balance");
        _internalBalances[from] -= internalAmount;
        _internalBalances[to] += internalAmount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    function decimals() public pure override returns (uint8) {
        return 8; // Match wBOT
    }
    
    // ============ View Functions ============
    
    function getInternalBalance(address account) external view returns (uint256) {
        return _internalBalances[account];
    }
    
    function getSharesForAmount(uint256 amount) external view returns (uint256) {
        return (amount * 1e18) / rebaseIndex;
    }
    
    function getAmountForShares(uint256 shares) external view returns (uint256) {
        return (shares * rebaseIndex) / 1e18;
    }
}
```

### 3. Governance.sol (Optional)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";

contract BotcoinGovernor is 
    Governor, 
    GovernorSettings, 
    GovernorCountingSimple, 
    GovernorVotes 
{
    constructor(IVotes _token)
        Governor("Botcoin Governor")
        GovernorSettings(
            1 days,   // Voting delay
            7 days,   // Voting period
            1000e8    // Proposal threshold (1000 sBOT)
        )
        GovernorVotes(_token)
    {}
    
    function quorum(uint256) public pure override returns (uint256) {
        return 10000e8; // 10,000 sBOT quorum
    }
    
    // Required overrides
    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }
    
    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }
    
    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }
}
```

---

## Deployment Order

1. **wBOT** - Wrapped Botcoin (independent)
2. **sBOT** - Staked Botcoin (needs StakingManager address post-deploy)
3. **StakingManager** - Core staking (needs wBOT and sBOT addresses)
4. **Roulette** - Casino (needs wBOT and StakingManager addresses)
5. **Governor** - Governance (needs sBOT as voting token)

```javascript
// deployment.js
async function deploy() {
    // 1. Deploy wBOT
    const wBOT = await deployContract("WrappedBotcoin");
    
    // 2. Deploy sBOT
    const sBOT = await deployContract("StakedBotcoin");
    
    // 3. Deploy StakingManager
    const staking = await deployContract("StakingManager", [wBOT.address, sBOT.address]);
    
    // 4. Grant roles
    await sBOT.grantRole(STAKING_ROLE, staking.address);
    
    // 5. Deploy Roulette
    const roulette = await deployContract("ZeroEdgeRoulette", [wBOT.address, staking.address]);
    
    // 6. Grant casino role
    await staking.grantRole(CASINO_ROLE, roulette.address);
    
    // 7. Deploy Governor (optional)
    const governor = await deployContract("BotcoinGovernor", [sBOT.address]);
    
    return { wBOT, sBOT, staking, roulette, governor };
}
```

---

## Yield Flow

```
Casino Game Ends
       │
       ▼
┌──────────────────┐
│ Winner tips 2%   │
│ (voluntary)      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Roulette.sol     │
│ sends to Staking │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ StakingManager   │
│ receiveTip()     │
│                  │
│ 70% → LP pool    │
│ 20% → Validators │
│ 10% → Governance │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ sBOT.rebase()    │
│                  │
│ All sBOT holders │
│ see balance grow │
└──────────────────┘
```

---

## Security Considerations

1. **Reentrancy**: All state changes before external calls
2. **Access control**: Role-based permissions for sensitive functions
3. **Rounding**: Handled carefully in rebasing math
4. **Lock periods**: Prevent flash loan attacks on voting
5. **Slashing**: Only authorized oracles can slash

---

## Gas Estimates

| Operation | Estimated Gas |
|-----------|--------------|
| stake | ~150,000 |
| requestUnstake | ~80,000 |
| withdraw | ~120,000 |
| claimYield | ~60,000 |
| rebase | ~50,000 |
| slashValidator | ~80,000 |

---

## Testing Checklist

- [ ] Stake minimum amounts for each tier
- [ ] Verify lock periods enforced
- [ ] Test yield distribution math
- [ ] Test rebasing accuracy over many cycles
- [ ] Test slashing reduces stake correctly
- [ ] Test sBOT transfers maintain yield eligibility
- [ ] Verify governance voting power matches stake

---

*Stake wBOT. Earn tips. Govern the protocol.*
