# Contributing — CipherLayer (family repo)

This is the family **meta repository** (ADR-F001): family-level docs, whole-family
verification (`system-test.sh`, `scripts/`), and family CI. Product code lives in
the sibling repos (`wallet/`, `browser/`, `scam-guard/`), each independently
licensed and versioned — see their own `CONTRIBUTING.md`.

## License and DCO

Contributions to this repository are accepted under [Apache-2.0](LICENSE). Every
commit must carry a `Signed-off-by` line (`git commit -s`), certifying the
[Developer Certificate of Origin](https://developercertificate.org). Security
findings: open a GitHub issue with the claim violated, a reproduction and the severity.

## Ground rules

1. Meta repo only: family docs, verification scripts, family CI. No product code,
   no `shared/` folder unless a real versioned cross-project artifact exists with
   its ownership and compatibility policy documented first.
2. Product repos are `.gitignore`d here, never tracked, never submodules.
3. A build failure in this repo must never block a product repo.

## Workflow

```bash
./system-test.sh   # whole-family live weave (needs Foundry)
```

- Small, auditable increments; one logical change per commit.
- Conventional commit messages (`feat:`, `fix:`, `docs:`, `chore:`, `test:`).
- No history rewriting, no force-push, no new remotes or pushes without operator
  authorization.
