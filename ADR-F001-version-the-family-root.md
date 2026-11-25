# ADR-F001 — Version the family root (meta repository)

**Status:** Accepted (operator, 2026-07-16) · **Scope:** the `CipherLayer/` parent directory only

## Context

The founding rule (root `README.md`) declared the parent directory an organizational container: *"No `.git/` here."* The intent — no shared production code, no accidental coupling between the three product repos — was and remains correct.

But the root accumulated load-bearing artifacts that the rule left unprotected: `system-test.sh` (the only whole-family live-weave verification), `BUILD-STATE.md`, `GLOSSARY.md`, the family guide, and the Tier-0 review scripts (`scripts/`). None were versioned, reviewed, or CI-run. On **2026-07-16** this bit concretely: `system-test.sh` had silently broken (5/6) because it was never updated for the wallet's protocol v0.3 host attestation (ADR-013) — the exact class of drift the per-repo CI gates can never catch, discovered only because someone happened to run it.

## Decision

Initialize a **meta repository at the family root** that versions family-level artifacts only:

- Family docs: `README.md`, `BUILD-STATE.md`, `GLOSSARY.md`, `CIPHERLAYER-FAMILY-GUIDE.md`, session summaries, this ADR.
- Family verification: `system-test.sh`, `scripts/` (family-review loop, pin-drift check).
- Family CI: `.github/workflows/` (nightly live-weave job).

The three product repositories stay exactly what they were — **independent git repos with their own history, CI, and release lifecycle** — and are explicitly `.gitignore`d here. They are *not* submodules, *not* subtrees, and this repo must never reference their code by relative path in anything that ships.

## Rules preserved (the original intent, restated)

1. **No shared production code in this repo.** Docs, verification scripts, and CI only. A build failure here can never block a product repo.
2. **No production coupling via the parent.** Cross-repo artifacts still travel only through pinned, versioned `exports/` → `imports/` copies (PIN.json provenance).
3. **No submodules.** Sibling checkout for CI is done by the workflow, at branch heads, read-only.
4. **Dependency direction unchanged:** `scam-guard → wallet → browser`.

## Consequences

- `BUILD-STATE.md`, `GLOSSARY.md`, and `system-test.sh` get history, review, and a place to receive fixes as commits (today's v0.3 attestation fix is the first).
- A scheduled workflow (`family-weave.yml`) can run the live cross-product weave nightly against the three repos' `main` heads — the drift class that broke `system-test.sh` becomes a red X instead of a silent lie. Because the product repos are **private**, the workflow needs a fine-grained PAT with read access to all three, stored as the `FAMILY_TOKEN` actions secret; until that secret exists the job fails at checkout (documented in the workflow header).
- The root `README.md` rule changes from "no `.git/` here" to "meta repo, products ignored" — this ADR is the required record of that change.

## Alternatives considered

- **Relocate `system-test.sh` into one product repo** — rejected: no single repo owns the family view; putting the weave in (say) `browser/` inverts the dependency direction in spirit.
- **Keep the root unversioned, rely on discipline** — rejected by evidence: discipline already failed silently once.
