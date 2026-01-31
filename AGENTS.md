# AGENTS.md - Botcoin Build Guide

## Build & Run

Botcoin is a Bitcoin Core fork using CMake. Build with:

```bash
# Dependencies (Ubuntu/Debian)
sudo apt-get install build-essential cmake pkg-config \
    python3 libssl-dev libevent-dev libboost-all-dev \
    libsqlite3-dev

# Dependencies (Arch Linux)
sudo pacman -S cmake boost libevent openssl sqlite

# Build (CMake)
cmake -B build
cmake --build build -j$(nproc)

# Binaries will be in build/bin/
```

## Validation

Run these after implementing to get immediate feedback:

- Build: `cmake --build build -j$(nproc)`
- Unit tests: `ctest --test-dir build --output-on-failure`
- Specific unit test: `./build/bin/test_bitcoin --run_test=<suite>`
- Functional tests: `./test/functional/test_runner.py`
- Specific functional test: `./test/functional/<test>.py`

## Binaries

After build, binaries are in `build/bin/`:
- `botcoind` - Full node daemon
- `botcoin-cli` - Command-line RPC client
- `botcoin-tx` - Transaction utility
- `botcoin-wallet` - Wallet utility
- `botcoin-util` - Miscellaneous utility

## Operational Notes

- Source is in `src/`
- Branding: Bitcoin → Botcoin complete for core binaries
- RandomX integration pending (replacing SHA-256d)
- Data directory: `~/.botcoin` (Linux), `~/Library/Application Support/Botcoin` (macOS)
- Config file: `botcoin.conf`

## Key Files to Modify

- `src/kernel/chainparams.cpp` - Network parameters, genesis block
- `src/consensus/params.h` - Consensus rules
- `src/pow.cpp` - Proof of work (RandomX integration)
- `src/validation.cpp` - Block validation
- `CMakeLists.txt` - Build configuration, client name
- `src/CMakeLists.txt` - Binary target names
- `src/clientversion.cpp` - User agent
- `src/common/args.cpp` - Config filename, data directory
