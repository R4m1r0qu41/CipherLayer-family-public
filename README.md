# CipherLayer

**Core promise:** *Never sign blind. Never browse blind.*

This directory is the family **meta repository** (ADR-F001, 2026-07-16): it versions family-level docs, the whole-family verification (`system-test.sh`, `scripts/`) — and nothing else. Each product subdirectory is an independent Git repository with its own history, versioning, test commands, and release lifecycle; all three are `.gitignore`d here and are never submodules.

## The three sibling products

| Directory | Product | Role |
|---|---|---|
| [`wallet/`](wallet/) | **CipherLayer Wallet** (W4113T) | Primary implementation repository. Owns the trust spine: Vault, wallet core, CLI, chain registry, RPC manager, EVM adapter, transaction-intent schema, decoder, simulation adapter, policy engine, audit log, desktop wallet, browser-connect protocol, capability/permission models, institutional controls. |
| [`browser/`](browser/) | **CipherLayer Browser** (W3B) | Dedicated browser repository. Owns the browser shell, Web2 browsing competency, dapp detection, dapp capsules, provider/capability broker, browser-to-wallet integration, trusted confirmation surface, browser threat model, compatibility experiments, and the eventual dedicated browser. |
| [`scam-guard/`](scam-guard/) | **Scam Guard** (Fraud Prevention Layer, FPL) | Sibling fraud-detection product. Owns the detector interface, detector registry, Reason Codes, phishing/impersonation/drainer detection, fraud-mechanics classification, explainable risk outputs, and privacy-preserving platform adapters. |

## Sequencing: wallet-first (locked)

The implementation order is a locked product decision, not a preference:

> **Build the wallet and trust spine before the browser.**

The Vault is the trust anchor. The wallet, CLI, policy model, transaction-intent model, and signing pipeline must exist and be stable before the browser consumes them. The browser repository receives architecture documents, interfaces, threat models, and narrow compatibility experiments during the wallet phases — it does not become the primary implementation focus until the Wallet MVP gate is met (see `browser/docs/architecture/browser-mvp-gate.md`).

## Dependency direction

```text
scam-guard ──publishes detector contract──► wallet
scam-guard ──publishes detector contract──► browser
wallet ──publishes wallet/provider contract──► browser
```

- The **browser** may depend on versioned interfaces from wallet and Scam Guard.
- The **wallet** may depend on Scam Guard's versioned detector interface.
- **Scam Guard** must not depend on wallet or browser internals.
- No production coupling via relative filesystem paths (`../wallet/`, `../scam-guard/`). Shared schemas are copied into repository-owned `schemas/external/` directories with source, version, commit hash, checksum, and update procedure recorded.

## How the repositories interoperate

1. **scam-guard** publishes a versioned detector interface (detector output schema + Reason Code registry). Consumers vendor a pinned copy.
2. **wallet** consumes the detector interface through its `cipherlayer-risk` adapter crate and publishes the wallet/provider contract (browser-connect protocol, signing request/response, capability schema).
3. **browser** consumes both: it brokers dapp requests to the wallet through the versioned provider contract and surfaces risk evidence from the detector interface. It never duplicates the Vault or wallet trust core.

## Rules for this parent directory

- Meta repo only (ADR-F001): family docs, verification scripts, family CI. A build failure here must never block a product repo.
- Product repos are ignored, never tracked, never submodules.
- No shared production code here.
- No `shared/` folder unless a real, versioned cross-project artifact exists and its owner, versioning authority, release process, compatibility policy, consumers, and security impact are documented first.
