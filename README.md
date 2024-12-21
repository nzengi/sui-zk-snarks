# ZK-SNARK Verification on Sui Blockchain

This project implements zero-knowledge proof verification on the Sui blockchain.

## Features
- Zero-knowledge proof verification using BLS12-381 curve
- Batch verification support
- Admin controls for key management
- Fee-based verification service

## Usage

### Submit a Proof
```typescript
import { JsonRpcProvider, TransactionBlock } from '@mysten/sui.js';

const provider = new JsonRpcProvider();
const tx = new TransactionBlock();

// Create proof submission transaction
tx.moveCall({
    target: `${PACKAGE_ID}::interface::submit_proof`,
    arguments: [
        vk,          // Verification key object
        proofData,   // Proof bytes
        publicInputs,// Public inputs
        payment      // SUI payment coin
    ]
});

// Sign and execute transaction
const result = await signAndExecuteTransactionBlock({
    transactionBlock: tx,
});
```

### Update Verification Key (Admin)
```typescript
const tx = new TransactionBlock();
tx.moveCall({
    target: `${PACKAGE_ID}::interface::update_verification_key`,
    arguments: [
        adminCap,    // Admin capability
        vk,          // Verification key to update
        alpha, beta, gamma, delta, ic // New parameters
    ]
});
```

## Deployment
1. Build project:
```bash
sui move build
```

2. Deploy to mainnet:
```bash
sui client publish --gas-budget 200000000
```

## Security
- All cryptographic operations are implemented in Move
- Admin controls for key management
- Fee-based service to prevent DoS attacks

## License
MIT License

## Testing

### Run Tests
```bash
sui move test
```

### Test Coverage
- Empty input handling
- Large input processing (> block size)
- Invalid state handling
- Multiple update operations
- Standard SHA-256 test vectors
- Error cases