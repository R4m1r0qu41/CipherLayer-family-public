# CipherLayer — Glossary, Identifier Schemes & Version Index

**Updated:** 2026-07-16 (Vault process split, trusted surface, protocol v0.3, multi-chain adapters, browser MVP shell, managed Scam Guard execution) · Lives in the unversioned family root as a convenience index; the authoritative documents are inside the repos and win on any discrepancy. Update this file whenever an ID family grows or a contract version bumps.

---

## 1. Terms and acronyms

### Project & product names

| Term | Meaning |
|---|---|
| **CipherLayer** | The product family: Wallet + Browser + Scam Guard, one trust spine |
| **W4113T** | Product codename of the CipherLayer Wallet ("WALLET" in leetspeak) |
| **W3B** | Product codename of the CipherLayer Browser ("WEB") |
| **Scam Guard** | Public product skin of the FPL (see below) |
| **FPL** | Fraud Prevention Layer — the detector/risk engine sibling product (repo `scam-guard/`) |
| **The spine / trust spine** | The shared trust core: Vault + pipeline (decode→simulate→risk→policy→sign→audit) + detector interface |
| **Vault** | The only component that may hold keys and authorize signatures (Zone D) |
| **Capsule** | Per-dapp isolation unit in the browser (Zone B) |
| **US / BS / BP** | Source-document shorthand: **US** = Unified Scope v1.0 (controlling), **BS** = Browser Scope v0.1 (supporting), **BP** = Fable 5 build prompt v1.2 (highest precedence). The v0.3 modular scope is a supplementary browser-leg guide. |
| **CT** | Crypto Twitter — shorthand for the heavy-user persona community (UQ-001) |

### General engineering & security acronyms

| Acronym | Meaning |
|---|---|
| **ADR** | Architecture Decision Record — status/context/decision/alternatives/consequences/security/revisit |
| **UI / UX** | User Interface / User Experience |
| **CLI** | Command-Line Interface (the wallet's first surface) |
| **MVP** | Minimum Viable Product |
| **TCB** | Trusted Computing Base — the code that must be correct for security to hold |
| **IPC** | Inter-Process Communication (future Vault boundary transport) |
| **SBOM** | Software Bill of Materials |
| **STRIDE** | Threat-modeling method (Spoofing, Tampering, Repudiation, Info disclosure, DoS, Elevation) |
| **DoS** | Denial of Service |
| **JSONL** | JSON Lines — one JSON object per line (audit log format) |
| **PIN / PIN.json** | Pinned cross-repo import manifest (Arrow/Tarquin format): source repo, version, commit, sha256, purpose |
| **SEP** | Secure Enclave Processor (Apple) — preferred anchor for the macOS trusted confirmation surface (UQ-003) |
| **CI** | Continuous Integration — GitHub Actions on all three repos (`make ci` gates + wallet Anvil job) + nightly family-invariant checks |

### Web3 / EVM acronyms

| Acronym | Meaning |
|---|---|
| **EVM** | Ethereum Virtual Machine — first chain family; Solana and Bitcoin adapters landed under the ADR-015 adapter-gate program (ADR-016/017) |
| **EOA** | Externally Owned Account — a plain key-controlled account |
| **RPC** | Remote Procedure Call — node endpoint; classes: local / self-hosted / public / premium |
| **Anvil** | Foundry's local development EVM chain (chain-id **31337**) — the default signing chain in the prototype (Sepolia is reachable only through the operator-driven external-signer flow, ADR-011) |
| **ERC-20** | Fungible-token standard; `approve`/`transfer`/`transferFrom` are the decoder's core selectors |
| **Allowance / approval** | Permission for a spender contract to move your tokens; "unlimited" = ≥2²⁵⁵ or max-uint |
| **Permit / EIP-2612** | Allowance granted by signature instead of transaction — treated as high-consequence |
| **EIP-712** | Typed structured-data signing standard (full parsing = W1-remainder) |
| **EIP-1193** | The standard dapp↔provider JavaScript interface the browser broker will expose |
| **EIP-6963** | Multi-provider discovery announcement — implemented by the shell as the primary dapp-discovery mechanism (ADR-B005: `window.ethereum` + announceProvider, rdns `org.cipherlayer.browser`) |
| **MEV** | Maximal Extractable Value — protection features deferred; never to be claimed as absolute |
| **NFT** | Non-Fungible Token |
| **MPC** | Multi-Party Computation (future key-management path) |
| **WalletConnect** | Wallet↔dapp connection protocol (assessed for the external-signer path) |
| **MetaMask** | Browser-extension wallet — operator-designated first external-signer integration (AC-004) |
| **SIWE / DID / VC** | Sign-In with Ethereum / Decentralized Identifier / Verifiable Credential (later identity layer) |
| **Ordinals / Ethscriptions** | Bitcoin/Ethereum inscription assets (deferred asset classes) |

### Component status labels (BP §16 — used in every repo)

`production-ready` (only after review+hardening — **nothing is today**) · `prototype` (functional, not audited) · `experimental` (feasibility) · `mocked` (simulated boundary, no real isolation) · `deferred` (out of scope on purpose) · `theoretical` (architecture only). "Secure" is never used as an unqualified status.

---

## 2. Identifier schemes (what an ID tells you, where it lives)

| Scheme | Format / examples | What it identifies | Registry location | Count |
|---|---|---|---|---|
| **ADR-nnn / ADR-Bnnn** | ADR-001…019 (wallet), ADR-B001…B005 (browser), ADR-001 (scam-guard), ADR-F001 (family) | Architecture Decision Records | `wallet/docs/adr/`, `browser/docs/adr/`, `scam-guard/docs/`, family root | 19 + 5 + 1 + 1 (ADR-019 = protocol v0.4; ADR-B005 = native dapp discovery) |
| **AC-nnn** | AC-001…AC-009 | Ambiguity/Conflict register entries (early numbering) | `wallet/docs/requirements/ambiguities-and-conflicts.md` | 9 |
| **CL-AMB-nnn** | CL-AMB-010…013 | Same register, later entries (scheme unified going forward: new entries use CL-AMB-nnn) | same file | 4 |
| **UQ-nnn** | UQ-001…UQ-005 | Unresolved questions in that register | same file | 5 (4 operator-resolved, 1 open: UQ-004 license) |
| **CL-XXX-nnn** | CL-VLT-001, CL-POL-007… | Requirements matrix rows. Families: **VLT** vault · **WAL** wallet core/CLI · **INT** intent · **EVM** decoding · **SIM** simulation · **POL** policy · **FPL** risk/Scam Guard · **AUD** audit · **PRV** provider · **BRW** browser · **LEG** legal · **ENG** cross-cutting engineering | `wallet/docs/requirements/requirements-matrix.md` | 67 rows |
| **T-nn** | T-01…T-26 | Wallet threat-model rows (STRIDE-informed) | `wallet/docs/threat-model/threat-model.md` | 26 |
| **BT-nn** | BT-01…BT-12 | Browser threat-extension rows | `browser/docs/threat-model/browser-threat-extension.md` | 12 |
| **AC-A…AC-L** | AC-A "unlimited-approval drain"… | Abuse-case narratives (letters, distinct from AC-nnn conflicts) | `wallet/docs/threat-model/abuse-cases.md` | 12 |
| **SC-nn** | SC-01…SC-11 | Security-claims register rows (claim + limits + prohibited overstatement) | `wallet/docs/security/security-claims-register.md` | 11 |
| **LEG-nn** | LEG-01…LEG-12 | Legal/regulatory issue register rows | `wallet/docs/legal/legal-and-regulatory-issues.md` | 12 |
| **POL-XXX-nnn** | POL-APR-001, POL-RSK-002… | Deterministic policy reason codes (machine-readable decision reasons). Families: CHAIN, DENY, ALW, FUN, APR, LIM, UNK, SIM, RSK, OK | emitted by `cipherlayer-policy`; documented in code + data-flow doc | 16 in use |
| **SG-XXX-nnn** | SG-ALLOW-001, SG-UNK-001… | Scam Guard Reason Codes (detector findings; never renumbered, deprecation is a flag) | `scam-guard/registry/reason-codes.v1.json` (operative, v1.1) | 17 codes |
| **Lifecycle states** | RECEIVED…CONFIRMED + failure states | Signing state machine states (SCREAMING_SNAKE_CASE on the wire) | `wallet/docs/architecture/signing-state-machine.md`; `cipherlayer-types::state` | 23 |
| **FPL-REQ-nnn** | FPL-REQ-001…014 | FPL requirements status rows | `scam-guard/docs/requirements.md` | 14 |
| **RFC-nnn (FPL)** | RFC-001…004 | FPL standards-track RFCs (vision, risk scoring, reason-code registry, detector interface — RFC-004 is Draft) | `scam-guard/docs/` | 4 of 9 planned |
| **W0–W5 / B1–B3** | W1 = wallet core+CLI, W2 = desktop (Wallet MVP gate), B1/B2 = browser phases | Roadmap phases (US §12) | `wallet/docs/roadmap/implementation-roadmap.md` | — |
| **Zones A–G** | Zone D = Vault | Trust zones (BS §7.1) | `wallet/docs/architecture/trust-boundaries.md`, `browser/docs/architecture/trust-zones.md` | 7 |
| **TB-n** | TB1…TB5 | Trust-boundary crossings in the wallet | `wallet/docs/architecture/trust-boundaries.md` | 5 |

---

## 3. Version-control index (contracts, schemas, repos)

### Published cross-repo contracts (the pin surface)

| Contract | Version | Owner (exports) | Pinned by (imports) | Owning commit |
|---|---|---|---|---|
| Detector interface (output schema, Reason Codes, contract doc) | **0.1.0** (registry instance v1.1; wallet re-pinned 2026-07-12 with ADR-018 registry validation) | `scam-guard/exports/` | `wallet/imports/scam-guard/`, `browser/imports/scam-guard/` | per-artifact, see PIN.json |
| Browser-connect (protocol doc + envelope, signing-request/response, dapp-permission, wallet-capability, rpc-query) | **0.2.0** (protocol_version **0.4** — ADR-019: envelope v1.1 `typed_data`/`personal_message` kinds, signing-response v1.3 `signature_hex`, rpc-query.v1 read-only whitelist proxy; additive, v0.3 shapes unchanged) | `wallet/exports/browser-connect-v0.1/` | `browser/imports/wallet/` (pinned 2026-07-17) | `f64682e` |

Pin mechanics: producer publishes to `exports/` (+ SHA256SUMS); consumer holds read-only copies + `PIN.json` (source commit, per-file sha256, pinned_at, update procedure). Never edit pinned files in place.

### Wire schemas (wallet `schemas/`, JSON Schema 2020-12)

17 schemas, all instance-versioned `schema_version: "1.x"`: wallet-capability, dapp-permission, **transaction-request-envelope (v1.1 — `payload.kind` typed_data/personal_message, ADR-019)**, **transaction-intent (v1.1 — `domain_chain_id_matches`)**, simulation-result, **policy (v1.1 — `unlimited_approval_override`, AC-005)**, **signing-request (v1.2 — nullable user_authorization for vaultd confirm_and_sign)**, **signing-response (v1.3 — `signature_hex`; `review_evidence`, ADR-014)**, **vault-signing-response (v1.1 — `signature_hex`, VLT-MSG-001)**, **policy-decision (v1.1 — simulation `not_applicable`)**, **rpc-query (v1 — read-only whitelist proxy, new in ADR-019)**, risk-evidence-bundle, audit-event, chain-registry-entry, rpc-profile, agent-authorization, plus the pinned detector-output. Conventions (decimal-or-hex quantity strings, null = evaluated-unknown, `ext` extension object, breaking ⇒ new file): `wallet/schemas/README.md`.

### Repositories

| Repo | Head | Commits | State | What it governs |
|---|---|---|---|---|
| `wallet/` | `f64682e` | 50 | vertical slice + vaultd process split + trusted surface tier v1 + external signer (Sepolia) + Solana/Bitcoin adapters + managed Scam Guard execution + supply-chain/property-test gates + **browser-connect protocol v0.4 (ADR-019): typed-data/personal_sign signing end-to-end, read-only rpc_query proxy**; all suites green; remote CI; Apache-2.0 | trust spine, contracts origin, requirements/threat/claims registers, ADR-001…019 |
| `browser/` | `4c7de41` | 28 | **gate OPEN (ADR-B003); Tauri MVP shell (ADR-B004) on protocol v0.4** — typed-data/personal_sign forwarded, read-only RPC proxied, native discovery via `window.ethereum` + EIP-6963 (ADR-B005); 13 live harness checks; remote CI; Apache-2.0 | trust zones, capsules, broker, confirmation surface, per-site permissions, engine comparison, packaging (UQ-005), Web2 competency, BT threat extension, compat matrix, **the gate checklist** |
| `scam-guard/` | `ec74fe3` | 15 | 5 deterministic detectors + risk engine + `scam-guard` CLI + adversarial corpus (21 cases) + RFC-004 draft; honest Medium for unverified TLD swaps; 31 tests; offline-only; remote CI; Apache-2.0 | detector interface v0.1, operative Reason Code registry v1.1, founding docs (RFC-001/ADR-001), RFC-004 draft, FPL requirements status |
| parent `CipherLayer/` | meta repo (ADR-F001, 2026-07-16) | — | `README.md`, this glossary, `system-test.sh`, `scripts/` | family map, dependency direction, whole-family verification |

### Governing document quick-map

| To find… | Go to |
|---|---|
| Hard security invariants binding all agents | `wallet/AGENTS.md` (+ per-repo AGENTS.md) |
| What's real vs mocked right now | `wallet/docs/security/prototype-limitations.md` |
| Why any architectural choice was made | `wallet/docs/adr/ADR-001…010` |
| Every requirement + its status/test | `wallet/docs/requirements/requirements-matrix.md` |
| Every ambiguity + the operator's ruling | `wallet/docs/requirements/ambiguities-and-conflicts.md` (v0.2) |
| What may be publicly claimed about security | `wallet/docs/security/security-claims-register.md` |
| When browser work may start | `browser/docs/architecture/browser-mvp-gate.md` |
| How the suite/browser will be packaged | `browser/docs/architecture/packaging-and-distribution.md` |
| Dev commands | `wallet/Makefile`, `scam-guard/Makefile` (`make help`) |
| Whole-family verification | `system-test.sh` (root): per-repo CI gates + browser→wallet over the live socket + FPL weave + decode→scam-guard pipe |
