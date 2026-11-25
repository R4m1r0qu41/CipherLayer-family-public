# CipherLayer — Family Guide, Pipeline, Pending Work & Commercial Assessment

**Version:** 1.0 · **Date:** 2026-07-07 · Lives in the unversioned family root (`~/Dev/CipherLayer/`) as a convenience index alongside `BUILD-STATE.md` and `GLOSSARY.md`. The authoritative documents live inside each repo and win on any discrepancy. This is a map, not a source of truth.

The family is three independent products under one trust spine, dependency direction one-way (`scam-guard → wallet → browser`), meeting only at pinned wire contracts (ADR-002). GitHub: `R4m1r0qu41/W4113T-public` (wallet), `R4m1r0qu41/W3B-public` (browser), `R4m1r0qu41/ScamGuard-public` — all private, all with green CI.

---

## 1. Normative documents — what the acronyms mean and what they govern

### Source documents (highest authority, top-down)

| Acronym | Document | Governs |
|---|---|---|
| **BP** | Fable 5 build prompt v1.2 | **Highest precedence.** Behavioural rules, honesty discipline, custody vocabulary, forbidden claims. |
| **US** | Unified Scope v1.0 (`wallet/docs/source/…Unified_Scope…`) | Controlling product scope for the whole stack. |
| **BS** | Browser Scope v0.1 (`…Browser_Full_Project_Scope…`) | Supporting scope for the browser leg (the 15-step MVP acceptance is BS §22). |

Precedence when they conflict: **BP > US > BS**, recorded in each repo's requirements matrix and the ambiguities-and-conflicts register.

### Decision & specification record types

| Type | Meaning | Where | Governs |
|---|---|---|---|
| **ADR** | Architecture Decision Record (status/context/decision/alternatives/consequences/security/revisit) | `wallet/docs/adr/ADR-0xx`, `browser/docs/adr/ADR-B0xx` | Binding architecture choices. |
| **RFC** | Request For Comments (standards-track spec) | `scam-guard/docs/RFC-00x` | FPL vision, scoring, reason-code registry governance. |
| **PIN / PIN.json** | Pinned cross-repo import manifest (source repo, version, commit, sha256, purpose) | `<repo>/imports/<sibling>/PIN.json` | How contracts cross repo boundaries — the *only* legal cross-repo coupling. |
| **Requirements matrix** | Normalized requirement rows (`CL-*` ids) with source, phase, status, verification | `wallet/docs/requirements/requirements-matrix.md` | Traceability from scope to implementation. |

### The ADRs (wallet, `ADR-0xx`)

- **001** wallet-first sequencing · **002** three repos not monorepo · **003** Rust trust core + TypeScript presentation · **004** Vault process boundary (*implemented: `cipherlayer-vaultd`*) · **005** test-key strategy (Anvil dev keys only) · **006** EVM-first chain strategy · **007** local-first audit log · **008** simulation-adapter boundary · **009** external FPL detector interface · **010** browser implementation gate · **011** external-signer transport & Arrow scope · **012** trusted confirmation-surface tier (*macOS system dialog + phrase, tier v1*) · **013** transport v0.3 host attestation (*closes capsule-id forgery*).

### The ADRs (browser, `ADR-B0xx`)

- **B001** scoped gate opening (transport + broker + harnesses) · **B002** engine selection (Tauri/system-WebView + separate Vault process; **no Chromium fork**) · **B003** full gate opening for the MVP shell (**Accepted 2026-07-07 — gate is open**).

### The RFCs (scam-guard)

- **RFC-001** Fraud Prevention Layer vision · **RFC-002** risk scoring (0–100 derived score, subordinate to the severity level; `null` off-axis) · **RFC-003** reason-code registry governance (codes never reused/renumbered). Plus **ADR-001 (Privacy-First)**: collects nothing; every subject is caller-supplied.

### Security governance documents

| Document | Location | Governs |
|---|---|---|
| Threat model (T-01…T-26) | `wallet/docs/threat-model/threat-model.md` | STRIDE register over trust boundaries; `mitigated/partial/accepted/n-a-P` status per threat. |
| Browser threat extension (BT-01…BT-12) | `browser/docs/threat-model/browser-threat-extension.md` | Browser-specific threats; each row has a disposition (mitigate-MVP / accept-label / defer-trigger). |
| Security-claims register (SC-01…SC-11) | `wallet/docs/security/security-claims-register.md` | Every user-facing security claim + its limitations + forbidden overstatements. Nothing ships in marketing that isn't registered. |
| Prototype-limitations | `wallet/docs/security/prototype-limitations.md` | Honest "what is MOCKED / prototype / theoretical" table. |
| Abuse-cases | `wallet/docs/threat-model/abuse-cases.md` | Adversary scenarios. |

### Identifier schemes (so a code in a log is legible)

| Prefix | Domain | Examples |
|---|---|---|
| **T-xx** | Wallet threats | T-12 fake confirmation, T-14 local malware, T-18/T-19 transport/deputy |
| **BT-xx** | Browser threats | BT-01 capsule escape, BT-05 surface imitation |
| **C-1/C-2** | Browser review residuals | C-1 capsule-id integrity (*closed*), C-2 surface tier |
| **SC-xx** | Security claims | SC-05 key isolation, SC-11 wallet-owned confirmation |
| **CL-*** | Requirements | CL-VLT-003 vault process, CL-WAL-010 external signer |
| **POL-*** | Policy reason codes | POL-APR-001 unlimited approval, POL-RSK-002 unknown risk escalates |
| **VLT-*** | Vault refusal codes | VLT-LCK-001 locked, VLT-USR-001 rejected at surface, VLT-SUR-001 fail-closed |
| **SG-*** | Scam Guard findings | SG-DOM-* domain, SG-IMP-* impersonation, SG-ALLOW-* intent, SG-DRAIN-* drainer |
| **UQ-xxx** | Open operator questions | UQ-003 SEP-backed surface |
| **ATK1–10 / A1–A9** | Attackers / assets | ATK1 malicious dapp, A1 key material |

---

## 2. Implementation pipeline so far

### 2a. Wallet (W4113T) — the trust spine

The signing pipeline, each stage a crate, state-machine-ordered, hash-chain-audited:

```
validate → permission → decode → simulate → risk → policy → USER_REVIEW → vault(sign) → broadcast → audit
```

| Crate | Role |
|---|---|
| `cipherlayer-types` | Shared types + the 23-state signing state machine (property-tested) |
| `cipherlayer-provider` | Envelope validation, mandatory caller identity, permission store (keyed by `(kind, origin, capsule_id)`), the **v0.3 transport** (`connect serve`) |
| `cipherlayer-evm` | Deterministic calldata decoder (approve/transfer/permit/setApprovalForAll…); unknown is a first-class answer |
| `cipherlayer-intent` | Decoded transaction intent (versioned schema) |
| `cipherlayer-simulation` | Anvil state-diff simulation; failure is first-class; limitations always attached |
| `cipherlayer-risk` | Aggregates detector findings; `unknown` never becomes `low`; disagreement = `conflicting` |
| `cipherlayer-policy` | Deterministic policy engine, `POL-*` reason codes; unlimited-approval default-deny |
| `cipherlayer-vault` | The only signer authority; capability validation, lock state; **IPC wire format + client** |
| `cipherlayer-vaultd` | **The Vault as its own OS process** (ADR-004) + the **macOS trusted confirmation surface** (ADR-012) |
| `cipherlayer-audit` | Append-only SHA-256 hash-chained JSONL log + verify |
| `cipherlayer-cli` | Drives the whole pipeline; the **W4113T operator console**; `connect serve` transport |

Milestones done: full vertical slice; real EVM signature on Sepolia (external-signer, ADR-011); **Vault process split** (criterion 2); **trusted confirmation surface** tier v1, red-teamed (criterion 4); **transport v0.3 host attestation** (closes C-1).

### 2b. Scam Guard (FPL) — the fraud engine

`fpl-core` (five deterministic detectors: domain intelligence, identity/impersonation via confusable folding, command detection, high-consequence asks, intent-allowance) + unified risk engine (RFC-002 score) + 17-code registry (RFC-003) → `fpl-cli` (`check domain|url|text|intent`, `codes`, `capabilities`, `--json`). Privacy-first (ADR-001): collects nothing. 30 tests.

### 2c. Browser (W3B) — the isolating shell

`broker-core` (Zone C, zero authority): hand-mirrored wire types (linking wallet crates is forbidden), deny-by-default method classification, EIP-1193 error mapping (page sees coarse 4001/4100, never *why*), the **v0.3 socket client with host attestation**. Three sanctioned experiments in `prototypes/`: `provider-harness` (7 contract paths), `webview-harness` (real WKWebView injection), `capsule-isolation` (measured C-1, now proves it closed, 6/6). Engine selected (ADR-B002). **Gate open (ADR-B003); no product shell built yet.**

### 2d. The three-way integration

Three live weave points, all over pinned wire contracts, no shared code:

1. **Scam Guard → Wallet**: `FplCliDetector` runs the scam-guard binary as a subprocess over the pinned detector contract; findings inform the risk step; a live unlimited-approval flows SG-ALLOW-001 → risk High → policy deny.
2. **Wallet → Browser**: the broker drives a full dapp session over the wallet's v0.3 socket (connect → confirmed transfer → policy denial → revoke), host-attested.
3. **Direct pipe**: `cipherlayer-cli decode … | scam-guard --json check intent -`.

**One command proves it all:** `./system-test.sh` (family root) — per-repo CI gates → Anvil → wallet transport with the real FPL detector → browser harness → wallet integration suites + the weave. Everything dev-chain (31337), Anvil keys, no real funds.

---

## 3. Where the relevant files live

| What | Path |
|---|---|
| Family system test | `/system-test.sh` |
| Family build state / glossary | `/BUILD-STATE.md`, `/GLOSSARY.md` |
| CI workflows | `<repo>/.github/workflows/ci.yml` |
| Wallet pipeline | `wallet/crates/cipherlayer-cli/src/pipeline.rs` |
| Transport (v0.3, host attestation) | `wallet/crates/cipherlayer-cli/src/serve.rs` |
| Vault daemon + confirmation surface | `wallet/crates/cipherlayer-vaultd/src/{main,surface}.rs` |
| Vault core + IPC wire | `wallet/crates/cipherlayer-vault/src/{lib,ipc}.rs` |
| Operator console | `wallet/crates/cipherlayer-cli/src/console.rs` (+ `docs/console-guide.md`) |
| Wire schemas (pinned) | `wallet/schemas/*.v1.json` |
| Cross-repo pins | `<repo>/imports/<sibling>/PIN.json` |
| Broker | `browser/crates/broker-core/src/{transport,eip1193,wire}.rs` |
| Browser experiments | `browser/prototypes/{provider-harness,webview-harness,capsule-isolation}/` |
| FPL detectors | `scam-guard/crates/fpl-core/src/detectors/` |
| Runtime state (gitignored) | `wallet/data/` (audit log, permissions, vault lock, `confirm-phrase` 0600, `connect-host-token` 0600, signer aliases) |
| Env config | `wallet/.env.example` (documents `CIPHERLAYER_*` vars) |

Key env vars: `CIPHERLAYER_VAULT_SOCKET` (route signing to vaultd), `CIPHERLAYER_CONNECT_HOST_TOKEN` (host attestation), `CIPHERLAYER_CONFIRM_PHRASE_FILE` / `CIPHERLAYER_CONFIRM_AUTO`, `CIPHERLAYER_QUICKNODE_SEPOLIA_URL` / `CIPHERLAYER_SEPOLIA_RPC`, `CIPHERLAYER_FPL_BIN`.

---

## 4. Pending items

### Named by the operator

| Item | Status | Blocking condition |
|---|---|---|
| **Chromium/CEF fork** | Explicitly closed | Needs its own ADR + operator sign-off + funded maintenance plan (ADR-B002). Current evidence says *not needed* — WebView isolation + wallet permission scoping suffice. |
| **Real custody** (real keys/funds) | Closed by ADR-005 | Every `accepted-P` threat row (T-04/T-11/T-12/T-14) becomes blocking first; needs hardware-backed keys / OS keychain / external audit anchoring. |
| **Distributed / signed release** | Closed | Needs the release-security pipeline (signed releases, provenance, staged rollout, rollback) — browser threat BT-11. |
| **Extension / plugin runtime** | Closed (defer-trigger) | Reopens BT-04; needs a capability-scoped, signed-plugin design that can never touch the Vault or confirmation surface. |

### Other pending (from the gates, ADRs, and threat model)

- **Criterion 1 residual**: one external **review cycle** (remote CI now done).
- ~~**Transport concurrency**~~ (ADR-B002 finding 2) — **closed 2026-07-08**: the socket now serves one task per accepted connection (`Arc<Mutex<Pipeline>>` for correctness-critical state, lock-free `Arc<ChainRegistry>` for reads); proven with a regression test that fails against the old code and passes against the fix.
- **Confirmation surface tier 2** (C-2): SEP/biometric binding + occlusion detection; "trusted surface" stays a qualified claim (SC-11) until then.
- **The Tauri MVP shell itself** (BS §22, fifteen steps) — the gate is open for it.
- **Attestation residual** (C-1): a same-user attacker who reads the launch token = local malware (T-14); closing it needs OS keychain-gated token or per-capsule OS isolation.
- **Deferred wallet capabilities**: hardware/secure-storage backends (interface stubs only), multi-provider simulation comparison, post-execution divergence alerts, audit external anchoring, agent/session-key runtime, fuzzing in CI.
- **FPL RFC track**: RFC-004…009 (detector interface spec, response policy, consent model, identity detection, browser integration, then AI as an *enhancement* only).
- **License** (UQ-004): resolved 2026-07-16 — the whole family is Apache-2.0 with a DCO contribution requirement (`LICENSE` + `CONTRIBUTING.md` in every repo).

---

## 5. Roadmap to the pending items

**Phase A — finish the transport & ship the shell (weeks)**
1. ~~Transport concurrency (wallet)~~ — **done**.
2. Tauri MVP shell (browser): host process, one WebView per capsule, custom-protocol-per-capsule origins, provider injected pre-page, broker bridge, host attests + assigns capsule ids, USER_REVIEW on vaultd surface. Walk the 15 BS §22 steps on testnet. *Now the only blocker before this can start.*
3. External review cycle → fully closes criterion 1.

**Phase B — harden the trust surfaces (1–2 months)**
4. Confirmation surface tier 2: SEP/biometric binding (signed app bundle + entitlements) + occlusion detection → upgrades SC-11 from qualified to strong; retires C-2.
5. Secure storage backend: OS keychain / Secure Enclave for the (still test-only) key path; token via keychain closes the C-1 residual.
6. Audit external anchoring + post-execution divergence alerts.

**Phase C — the custody gate (the big one, quarter-plus)**
7. Everything in the threat model's `accepted-P` set becomes a blocking requirement. Hardware-wallet signer path first (external custody, never native seed in the prototype's spirit). Independent security review. Only then may a real key or fund touch the system.
8. Release-security pipeline (signed releases, provenance, staged rollout) → unblocks a distributed build (BT-11).

**Phase D — optional expansions (demand-driven, each its own ADR)**
9. Extension/plugin runtime (capability-scoped, signed) if third-party integrations are wanted.
10. Chromium/CEF fork *only* if compatibility data proves WebView-class isolation insufficient.
11. FPL AI enhancement layer (advisory-only, never authorizing) after the deterministic RFC track.

---

## 6. Upgrade suggestions per product

**Wallet**
- Multi-provider simulation (cross-check two RPCs) — directly retires the biggest simulation caveat (T-07/T-08).
- Property-based fuzzing of the decoder + envelope parser in CI (T-24) — cheap, high-value.
- A read-path (balances/history) so the browser can render without a signing round-trip.
- Richer policy DSL (per-chain, per-origin allowance budgets) — the policy engine is the differentiator; make it expressive.

**Scam Guard**
- Wire the RFC-004+ detector interface so third parties can contribute detectors behind the same contract.
- Optional online enrichment (WHOIS/DNS/TLS) as a **separate, consent-gated** module — keep the offline core `unknown`-honest, add signal where the user opts in.
- Ship the CLI as a standalone product early (it already stands alone) — fastest path to real-world signal and revenue.

**Browser**
- Before the full shell, a single-capsule "proof shell" to exercise the 15 steps end-to-end with minimal surface.
- Per-site permission dashboard (the per-site-permissions model is a strong UX story — surface it).
- Treat the trusted-surface provenance markers as a brand asset (the secret phrase is a trust ritual users remember).

**Cross-cutting**
- Turn `system-test.sh` into a scheduled CI job across all three repos (the offline review loop below).
- A published `cipherlayer-contracts` package to replace copy-pinning (ADR-002 revisit trigger).

---

## 7. Offline-first review loop (model only on demand) — **implemented 2026-07-08**

Goal: keep the products and their integration verifiably healthy with **deterministic offline checks**, escalating to a model **only** for specific reviews or when a check fails. Cheap by default, smart on demand. Built and tested (including deliberate negative-test tampering, restored cleanly) this session.

### Tier 0 — deterministic, every run, no model

**Per-repo invariants** (`<repo>/scripts/family-invariants.sh`, folded into `make ci` / the CI gate job, also standalone via `make family-check`):

| Repo | Checks |
|---|---|
| Wallet | no `data/`/`.env` tracked · no key-shaped literal outside `cipherlayer-vault/`/`.env.example`/tests · `Vault` has exactly one constructor · `Vault`'s `Debug` redacts · every `schemas/*.v1.json` is `additionalProperties:false` · no `unsafe` Rust |
| Browser | no `data/`/`.env` tracked · **zero** exact-64-hex literals anywhere (browser must never hold key material at all — stricter than the wallet's rule) · no cross-repo `path =` dependency on wallet/scam-guard (ADR-002) · `broker-core` defines no `sign`/`authorize` function (zero authority) · no `unsafe` Rust |
| Scam Guard | no `data/`/`.env` tracked · `fpl-core`'s `Cargo.toml` declares no network-capable dependency (ADR-001 privacy-first, checked at the dependency-declaration level, not just by grepping usage) · no duplicate reason codes in the registry (RFC-003 never-reused) · no `unsafe` Rust |

**Cross-repo, root-level** (`~/Dev/CipherLayer/scripts/`, not tracked in git — the root is intentionally not a repo, ADR-002):
- `pin-drift-check.sh` — for every `imports/<sibling>/PIN.json`, verifies the local copy matches its recorded hash **and** that the producer's current `exports/` hasn't changed since the pin (handles both PIN.json layouts in use: the bundle/`files_sha256` style and the per-pin/`pins[].hash` style). Proven to actually detect drift, not just pass: a controlled test that tampered a producer export and re-ran it caught the drift correctly, then cleared once restored.
- `family-review.sh` — orchestrator. Default run (`./scripts/family-review.sh`, ~5s): the three per-repo invariant scripts + pin-drift-check. `--full` (~5 min): adds each repo's full `make ci` and `./system-test.sh` (the 6-point cross-product weave). Writes a machine-readable report to `.family-review/latest.json`.
- `family-review-triage.sh` — the **Tier-1 trigger** (below). Reads the report; decides whether a model is needed; never calls one itself.

Wired into each repo's `.github/workflows/ci.yml`: the invariants run on every push/PR (folded into the existing gate), and each workflow now also has a nightly `schedule:` trigger so drift is caught even with no push (e.g. a toolchain update).

*Deliberately not built*: a JSON-Schema-conforming envelope validator (no `ajv`/`jsonschema` in this environment; the existing Rust conformance tests — `browser_connect_conformance.rs`, the wire-serde round-trip tests — already assert wire shape via the real types, which is stronger than re-validating with a second, separately-maintained schema tool). Also not duplicated: `unknown`-never-`low` semantics, already asserted by `cipherlayer-risk`'s own unit tests — the shell layer doesn't re-test what the Rust suite already proves.

### Tier 1 — model escalation, only on a trigger

`family-review-triage.sh` maintains a per-repo watermark (`.family-review/state.json`: last-cleared commit SHA) and escalates (exit 2, human-readable reasons, suggested next command) when either:
- **(a)** the latest Tier-0 report has a failing check, or
- **(b)** a diff since the watermark touches a security-sensitive path per repo — wallet: `cipherlayer-vault/`, `cipherlayer-vaultd/`, `serve.rs`, `cipherlayer-policy/`, `schemas/`, `docs/threat-model/`, `docs/security/`, `docs/adr/`; browser: `broker-core/`, `docs/threat-model/`, `docs/adr/`, the trusted-surface and gate docs; scam-guard: `fpl-core/src/detectors/`, `registry/`, ADR-001, the RFCs.

Verified against a real historical diff: rolling the wallet watermark back to before the ADR-013 host-attestation commit correctly flagged exactly `serve.rs` + the new ADR + the two touched security docs — nothing else. Clean state → `exit 0`, silent. `--clear` advances the watermark after a human/model has acted (never auto-clears on its own — an unresolved escalation keeps re-surfacing, by design).

**Not yet wired**: an actual scheduled invocation that *acts* on an escalation (opens a PR, runs `/code-review`) is a deliberate stop short — that means paying for a recurring cloud agent, which is a cost/schedule decision worth confirming explicitly rather than assuming. The `schedule` skill (CronCreate) is the mechanism if wanted; run `./scripts/family-review.sh && ./scripts/family-review-triage.sh` on a cadence, and only invoke a model when triage exits 2.

---

## 8. Honest assessment — design, marketability, commercialization

### Design (what's genuinely strong)

- **The honesty architecture is the moat.** `unknown` is first-class end to end; `accepted-P` threats are enumerated, not hidden; every security claim is registered with its limitations and forbidden overstatements. In a category full of "bank-grade / unhackable" theater, *provable restraint* is a differentiator — especially post-FTX, for the institutional and prosumer segments.
- **Authority separation is real, not slideware.** Deterministic policy in front of signing; the Vault as the sole signer, now in its own process; AI/advisory can warn but never authorize; the browser can annoy but never sign. The capsule-isolation experiment *found and drove fixes to* real defects (origin-vs-capsule keying, capsule-id forgery) — the architecture is falsifiable and was falsified, then fixed.
- **Contracts hold under real use.** Three repos, one-way dependency, pinned wire contracts caught two integration gaps that inspection missed. This scales to third-party detector/integration ecosystems.

### Design (honest weaknesses)

- **It is a prototype protecting decision quality, not custody.** Only worthless Anvil keys; no hardware backing; single-binary memory model in CLI mode. The distance to a shippable custody product is real (Phase C) and is the expensive part.
- **Surface tier v1** resists spoofing only against non-privileged attackers; the strong claim needs SEP + occlusion work.
- **macOS-only** trusted surface today; other platforms fail closed (correct, but limits reach).
- **No product UI yet** — the browser shell, the thing an end user touches, is unbuilt (gate just opened).

### Marketability

- **Scam Guard is the fastest-to-market, lowest-liability piece.** It's a standalone, privacy-first, explainable fraud CLI/library with no custody exposure. It can ship to wallets, exchanges, and security teams as a detector service *now*, generating real-world signal and revenue while the custody path matures. **Lead with this.**
- **The wallet's policy + audit engine** is a B2B story: a compliance-grade "why did we/didn't we sign" trail and a deterministic policy layer that institutions can point auditors at. The tamper-evident audit log and reason-code discipline are enterprise features, not consumer ones.
- **The browser** is the highest-ceiling, highest-cost, most-crowded play (MetaMask, Rabby, Phantom, browser incumbents). Its wedge is *isolation + trusted confirmation + built-in fraud evidence* — credible, but it must reach a demoable shell before it's a story.

### Commercialization roadmap (pragmatic)

1. **Now → Q+1: Scam Guard as a product.** Package the FPL as a licensable detector API/SDK (RFC-004 interface). Design-partner with 1–2 wallets/exchanges. Zero custody risk; immediate feedback; revenue that funds the rest. This also stress-tests the detector contract that the whole family leans on.
2. **Parallel: Wallet policy/audit as a B2B compliance module.** Sell the deterministic policy + hash-chained audit to teams that need an explainable signing gate (treasury ops, custodians' internal tooling). Still test-key/testnet until Phase C.
3. **Q+2 → Q+3: Browser MVP as the flagship demo.** Build the Tauri shell (gate is open), walk the 15 steps on testnet, use the trusted-surface + capsule-isolation + fraud-evidence story for fundraising and design partners. *Do not* claim custody safety until Phase C clears.
4. **Q+4+: the custody gate.** Only with hardware-wallet/external-custody paths, independent security review, and the release-security pipeline does a real-fund product exist. This is the capital-intensive, liability-bearing step — sequence it last, fund it from (1) and (2).

**One-line honest take:** the engineering discipline is unusually good and the isolation/honesty architecture is a real, defensible position; the risk is not technical soundness but *time-to-a-touchable-product* and the capital wall at real custody — which is exactly why the sequencing should be **Scam Guard revenue → wallet B2B → browser flagship → custody last**, not the other way around.
