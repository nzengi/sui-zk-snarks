# 🔐 Sui ZK-SNARK: Zero-Knowledge Proof Verification on Sui Blockchain

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Sui Version](https://img.shields.io/badge/Sui-testnet-blue)](https://sui.io/)
[![Move Language](https://img.shields.io/badge/Language-Move-orange)](https://move-language.github.io/move/)

A high-performance, modular implementation of Zero-Knowledge SNARK (zk-SNARK) verification operations for the Sui blockchain, written in the Move programming language.

## 📑 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Usage](#-usage)
- [Security](#-security)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

- ✅ **ZK-SNARK Verification**: Efficient proof verification using BLS12-381 curve
- 🔄 **Batch Processing**: Optimized batch verification for multiple proofs
- 🔒 **Admin Controls**: Secure key management and access control
- 📊 **Event System**: Comprehensive event logging and tracking
- 🧪 **Testing**: Extensive test coverage with test vectors
- 🔍 **Hash Functions**: Implemented SHA-256 and hash-to-curve operations

## 🏗 Architecture

### Core Modules

1. **Verifier Module** (`zk_snark.move`)
   ```move
   struct VerificationKey has key { ... }
   struct Proof has store, drop, copy { ... }
   ```

2. **Cryptographic Operations** (`crypto.move`)
   - BLS12-381 curve operations
   - Pairing computations
   - Field arithmetic

3. **Hash Operations** (`hash.move`)
   - Hash-to-curve implementation
   - Domain separation techniques
   - SHA-256 operations

4. **Admin System** (`admin.move`, `admin_impl.move`)
   - Key management
   - Access control
   - Administrative operations

5. **Batch Processing** (`batch.move`)
   - Multiple proof verification
   - Optimized batch operations

6. **Utility Functions** (`utils.move`)
   - Vector operations
   - Serialization
   - Validation helpers

## 🚀 Installation

```bash
#
```
....