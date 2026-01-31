# Botherum EVM Compatibility

## Goal: 100% EVM Compatibility

Contracts from Base, Ethereum, Arbitrum, Optimism should deploy and run identically.

## Supported EIPs (Active from Genesis)

| EIP | Feature |
|-----|---------|
| 155 | Replay protection (chain ID) |
| 1559 | Fee market |
| 2930 | Access lists |
| 1014 | CREATE2 |
| 2929 | Gas cost increases for state access |
| 3198 | BASEFEE opcode |
| 3529 | Reduction in refunds |
| 3541 | Reject new contracts starting with 0xEF |

## Gas Costs

Identical to Ethereum mainnet. No custom gas modifications.

## RPC Compatibility

Full eth_* namespace support:
- eth_sendTransaction
- eth_call
- eth_estimateGas
- eth_getBalance
- eth_getCode
- eth_getLogs
- etc.

## Tooling Compatibility

Works with:
- Hardhat (just change RPC URL + chain ID)
- Foundry (forge, cast)
- Remix
- MetaMask
- ethers.js / web3.js / viem

## Contract Deployment

```javascript
// Same as any EVM chain
const provider = new ethers.JsonRpcProvider("http://localhost:8645");
const wallet = new ethers.Wallet(privateKey, provider);

// Deploy exactly like Ethereum/Base
const factory = new ethers.ContractFactory(abi, bytecode, wallet);
const contract = await factory.deploy();
```
