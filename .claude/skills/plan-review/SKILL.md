---
name: plan-review
description: >-
  Adversarial review of a technical plan, tracker issue, or epic BEFORE implementation — the plan-time
  counterpart to a diff review. Grounds the review in the repository's reality (lockfile versions,
  conventions, prior decisions, blast radius) and current best practice, diagnoses altitude failures —
  "fog" (too vague to start) and "tunnel" (detail without product vision) — then promotes the artifact
  to a v2 plan at the right altitude with a build verdict. Use when asked to review, sanity-check, or
  gate "is this ready to build": a plan-mode plan before approval, an issue ("review issue #123"), or an
  epic, where it additionally checks cross-child coherence. Gated by rules of engagement; skips trivial
  work. Prefer a repository-local planning skill (e.g. Verea's verea-plan) when the repo ships one.
  Read-only by default: reports in chat, and updates an issue body only on confirmation.
---

# Plan review

Review one frozen plan against the repository's reality and the present state of the art, then promote it.
This sits *before* code: write-time discipline and diff review come later; this is plan-time.
Stop at the review plus the promoted plan v2.

If the repository ships its own planning skill (for example Verea's `verea-plan`), use that instead —
it carries the repo's load-bearing checks. This skill is the portable engine.

## Rules of engagement (the gate)

Engage only when the artifact earns it.
Apply the gate first and say which side it landed on.

**Engage** when the plan/epic has at least one of:

- touches more than one package/module or a service boundary
- includes a DB migration, infrastructure change, auth, isolation boundaries (multi-tenancy,
  sandboxing), billing, a public API, or a new secret/env var
- introduces a new dependency, crosses a major/security boundary while upgrading one,
  or changes a decision already settled in an ADR / closed issue / the docs
- has ≥3 non-trivial workstreams, or any hard-to-reverse step (deploy, production data, release)
- is an epic with child issues

**Skip** (say "below threshold — skip", do nothing else) for: bugfix, refactor, rename,
routine dep-bump that crosses none of the engage conditions, docs, single-file changes, plans under
3 steps, or work that only re-applies an established repo pattern.

Severity reflects consequence, not effort: a one-line version bump can be a P0.
Do not engage to look thorough.

## Two ingresses

- **Tracker epic/issue** — read the issue body; for an epic,
  read each linked child and also run the cross-child coherence axis below.
  Freeze that text as the artifact.
- **Plan-mode plan** — the plan an agent produced (e.g. before `ExitPlanMode`).
  Freeze it as written.
  Lighter run: Track 1 stays mirrored on the touched paths, Track 2 narrows to the load-bearing
  decisions only.

## Phase 0 — Freeze

Capture the exact artifact under review verbatim so it can't drift mid-review.
Record its source (issue number, or "plan-mode").
For an epic, record the child set.

## Phase 1 — Build the senior

Earn the expertise the plan's author lacked.
Two tracks, code first.
See `references/research-playbook.md`.

1. **Domains.**
   Name the 2–5 load-bearing technical areas the plan rests on.
   Research is budgeted on these, not every line.
2. **Track 1 — code research (always).**
   Ground the review in what is true *here*: pinned versions in the repo's lockfile for every dependency
   touched; 2–3 existing implementations of the closest analogous feature
   (routing, errors, migrations, tests);
   prior decisions in the docs, closed and open issues, revealing commits; real constraints
   (deploy target, CI budget, data shape); blast radius (what actually imports/calls the changed surface).
   Prefer a context-isolated `Explore` subagent for broad sweeps.
   Defer to any project-local skills covering the domain (DB, infra) when present.
3. **Track 2 — web research (always on).**
   Find where the world moved past the training cutoff on the load-bearing decisions only
   (3–7 searches, dated).
   Deprecations, supersessions, security advisories, hard-won lessons.
   If web access is unavailable, run Track 1 fully, skip Track 2,
   tag every best-practice claim `[training-data, unverified]`, and name the decisions most likely to
   have shifted.

**Same-session isolation.**
When this session authored the artifact under review — a v1 from `plan-well`, or a plan-mode plan it
just wrote — do not run Phases 2 and 3 inline: an author reviewing its own text inherits its own
assumptions.
Delegate both phases to a fresh subagent whose prompt contains only the frozen artifact, the Phase 1
research summary, and the reference files — never the generation transcript.
The parent session verifies the returned findings, assembles the output, and writes the v2.
An artifact authored elsewhere (a human, another session) may be reviewed inline.

## Phase 2 — Diagnose altitude

Classify each section with the fog and tunnel tests in `references/review-rubric.md`.
A plan is usually mixed: fogged on the hard parts, tunneled on the easy ones — that inversion is itself
a finding.
Challenge every blacklisted vague word with the concrete question it is hiding from.

Then derive the **repo-specific load-bearing checks** from the repository's own instructions
(`AGENTS.md`, `CLAUDE.md`, contributing docs): isolation rules, secrets/config policy, migration
ownership, testing topology, feature-flag/rollout conventions.
Each one the plan leaves implicit is a finding at the severity the consequence warrants.
(The rubric is the portable engine; the repo's own rules are what fail hard *there*.)

## Phase 3 — Adversarial review

Steelman each choice before attacking it; if you can't, you don't understand it well enough to reject it.
Attack the text, not the author.
Concede when research validates the choice — record those under "What the plan got right".

Verify every finding: code claims carry `file:line`, best-practice claims carry source + date.
A finding without a concrete fix is a question — move it to "Open questions for humans", not a finding.
Normalize each surviving finding as:

```text
section/step — P0|P1|P2|P3 — altitude|fit|risk — description — evidence — suggested fix
```

Severity per the rubric's P0–P3 definitions.
Don't inflate: three real P0/P1s read as a serious review; ten padded ones read as noise.
Don't invent requirements the author never stated — those are open questions for the human.

## Epic axis — cross-child coherence (conditional)

Run only when the artifact is an epic with child issues.
Children can each be fine in isolation and still fail as a set.
Check, with evidence (cite child issue numbers):

- **Coverage** — do the children together achieve the epic's stated goal?
  A goal slice no child owns is a P1 gap.
- **Gaps** — is work the goal implies (migration, rollout, docs, the unhappy path) missing from every
  child?
- **Overlap** — do two children claim the same surface?
  That is a merge conflict and ownership ambiguity waiting to happen.
- **Sequencing** — is there a dependency order with a smallest shippable slice first, or a flat backlog?
  Name the dependency edges (child A blocks child B) the epic left implicit.
- **Boundary altitude** — each child is a plan in miniature; spot-check the hardest one or two with the
  fog tests.
  An epic whose hard child is itself fog has deferred the planning, not done it.

Fold these into the findings at the same P0–P3 severity,
and carry the resolved coverage and sequencing into the v2 plan.

## Phase 4 — Promote the plan (v2, always)

Rewrite the plan at the correct altitude, preserving what it got right:

- **Goal & non-goals** — who it's for, what they can do afterward, what is explicitly out of scope.
- **Decisions** — each load-bearing choice named (library + pinned version) with one-line rationale and
  evidence.
- **Design** — detail only where the risk is: the hard interfaces, failure paths, and quantities.
  Not the easy parts.
- **Sequencing (test-first)** — smallest useful version first; for an epic, the ordering spans children
  (which ships first, what it unblocks).
  Each step that changes application behaviour names its test *before* the implementation: the test that
  fails today and passes when the step is done, at the level the repo's testing topology assigns, and at
  a named **seam** — the public interface where the behaviour is observed (an exported function, an HTTP
  route, a CLI); a test aimed at internals is implementation-coupled and dies on the next refactor.
  Test-first is per step, not up-front in bulk: a plan that writes all the tests before any
  implementation verifies imagined behaviour.
  The step's done-condition is that test going green — and the test must be able to fail for the right
  reason (not a tautology; discriminating; hermetic; confirmed by reverting the code under test).
  Bugfix-shaped steps start from the test that reproduces the defect.
  Non-behavioural steps (infra, docs, config) carry their own proportionate verification instead.
- **Risks & rollback** — the hard-to-reverse steps and how to back out; name the rollout mechanism
  (a feature flag, where the repo has a flag system) and the rollback trigger for risky user-facing
  change.
- **Open questions** — product/judgment calls that belong to a human, not invented requirements.
  Present them as a numbered **frontier round**: only questions whose prerequisites are already settled
  (one whose answer depends on another open question waits for the next round), each with a one-line
  recommended answer.
  Facts are never questions — anything answerable from the repo or the web is Phase 1 research; only
  decisions go to the human.

## Output

Deliver in chat, always:

1. **Plan review** — altitude diagnosis, findings grouped by severity, "What the plan got right",
   and a one-line verdict: `ready to build`, `needs work`, or `research degraded` (Track 2 unavailable).
   Default to `needs work`; conclude `ready to build` only when no P0/P1/P2 survives verification.
   Don't judge whether a finding is deferrable to a follow-up — that is the plan owner's call:
   report it at its severity and let `needs work` stand.
2. **Promoted plan (v2)** — the rewrite above, plus a short delta explaining what changed and why.

For the **tracker epic/issue** ingress only: after presenting in chat,
offer to write the promoted plan v2 into the issue body
(e.g. `gh issue edit <#> --body-file …`, in the repository's language convention, body via temp file).
Do this **only on explicit confirmation** — never edit the issue, post comments, or push without it.
Immediately before editing, re-fetch the issue body and compare it byte-for-byte with the frozen
artifact; if it changed, abort the write and re-review the new version.
Plan-mode runs output to chat only.

Read-only otherwise: never edit code, commit, or push.
