# Senior research playbook

Reference for Phase 1 of `plan-review` (and `plan-well`): how the analyst earns expertise the artifact's
author lacked.
Two tracks, in order — code research grounds the work in the repository; web research grounds it in the
present.

## Track 1: code research (always)

Goal: know what is *true here* before judging the plan against it.
Prefer a context-isolated `Explore` subagent for broad sweeps; bring back conclusions, not file dumps.
Defer to any project-local skills covering the domain (DB, infra, architecture) when present.

Checklist per plan:

1. **Versions.**
   Read the repo's lockfile (`pnpm-lock.yaml`, `package-lock.json`, `uv.lock`, `Cargo.lock`, `go.sum`, …)
   for every dependency the plan touches; record exact pinned versions.
   Any step that assumes an API is checked against the pinned version's docs, not the latest.
2. **Conventions.**
   Find 2–3 existing implementations of the closest analogous feature.
   How does this repo do routing, errors, config, queries, migrations, tests?
   The plan either matches or justifies the break.
3. **Prior decisions.**
   Search the repo's instruction files (`AGENTS.md`, `CLAUDE.md`), docs, design notes, closed
   issues/PRs, and revealing commits on the touched paths.
   A plan that re-litigates a settled decision without knowing it was settled is a P0.
4. **Real constraints.**
   Deploy targets, CI time budget, environment/secrets policy, existing data volume and shape, and any
   isolation rules the repo enforces (multi-tenancy filters, sandbox boundaries).
   These kill more plans than design taste.
5. **Blast radius.**
   What actually imports/calls the surface the plan changes?
   The author's scope estimate is a guess; the dependency graph is a fact.
   Flag the high-blast-radius surfaces by name: isolation boundaries, auth, billing, DB migrations,
   CI merge gates, infrastructure/release.
6. **Tracked follow-ups.**
   Search *open* issues for the surface in play before calling any gap novel or unowned.
   Descoped work lives in the bodies of follow-up issues, not in the code;
   a "gap" that is already tracked is context for sequencing, not a finding.

## Track 2: web research (always on)

Goal: find where the world moved after the training cutoff.
Research the plan's *load-bearing decisions* (from Phase 1.1), not every line — typically 3–7 searches,
not 30.

### Query patterns

For each load-bearing decision, run the subset that applies.
Always pin the current year or "latest" — undated queries return training-era answers, which defeats the
point.

- `<library> changelog` / `<library> release notes <year>` — deprecations and new APIs since cutoff.
- `<approach> vs <alternative> <year>` — has the tradeoff flipped?
- `<pattern> deprecated` / `<pattern> considered harmful` — published reversals.
- `<library> security advisory` / the project's GitHub security tab — non-negotiable for auth, crypto,
  parsing, and anything touching user input.
- `site:github.com <library> issues <feature>` — maintainer-stated direction and known footguns.

### Source quality ranking

1. Official docs, changelogs, release notes, RFCs — cite freely.
2. Maintainer blog posts, GitHub issues/discussions where maintainers state direction.
3. Production postmortems and benchmarks (with dates and numbers).
4. Conference talks, well-known practitioner blogs — corroborate before citing for a P0/P1.
5. SEO listicles, AI-generated tutorials, undated content — never evidence, at most a pointer to a real
   source.

Every cited source gets a date check.
A "best practices" article from before the relevant major version is training-era knowledge wearing a
URL.

### What you are looking for

- **Deprecations** — the plan's approach is discouraged or removed in current versions.
- **Supersessions** — a newer pattern/API has clearly won (the old way's own docs pointing at the new
  way is the strongest signal).
- **Hard-won lessons** — advisories, postmortems, benchmarks that change the tradeoff the author made on
  priors.
- **Confirmations** — the choice still holds.
  Record these; they go in "What the plan got right".

### When to stop

- Each load-bearing decision has one primary source confirming/refuting it,
  or two independent secondary sources agreeing.
- Two consecutive searches on a decision return nothing newer than what you knew — mark it
  confirmed-by-absence, move on.
- Diminishing returns: budget belongs on P0/P1, not P3.
  If a finding is minor either way, don't research it.

### No web access

Run Track 1 fully, skip Track 2, tag every best-practice claim `[training-data, unverified]`,
in `plan-review` set the verdict to `research degraded`,
and name the decisions most likely to have shifted so the user can spot-check.
