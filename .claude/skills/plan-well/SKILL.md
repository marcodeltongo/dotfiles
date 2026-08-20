---
name: plan-well
description: >-
  Generative multi-lens planning: turn a raw idea, brief, tracker issue, or epic INTO a plan by analysing
  it through several independent expert perspectives (product, architecture, security, operability/SRE,
  QA, cost, devil's advocate — plus cross-child coherence for an epic), then synthesising consensus, real
  conflicts, and blind spots into a v1 plan at the right altitude. The upstream, divergent counterpart to
  plan-review: plan-well *generates* a plan, plan-review *critiques* one. Use when asked to "think
  through how to approach", "draft an epic/plan", "explore the approaches", or scope a fuzzy idea where
  multiple viewpoints help — before there is a plan to review. Gated by rules of engagement; skips
  trivial work. Prefer a repository-local planning skill (e.g. Verea's verea-plan) when the repo ships
  one. Read-only by default: reports in chat, and creates or updates an issue/epic only on explicit
  confirmation.
---

# Plan well

Turn a fuzzy idea or an under-shaped issue/epic into a plan,
by routing it through several independent lenses and synthesising what they agree on, where they
conflict, and what only one of them saw.
This sits *before* `plan-review`: plan-well is the divergent, generative step
(many viewpoints in, one v1 plan out);
`plan-review` is the convergent, adversarial step that critiques a plan and promotes it to v2.
plan-well never self-certifies "ready to build" — generation and judgement stay separate,
the same reason a diff review is separate from whoever wrote the code.
Stop at the synthesis plus the v1 plan.

If the repository ships its own planning skill (for example Verea's `verea-plan`), use that instead —
it carries the repo's load-bearing checks. This skill is the portable engine.

The lens catalogue, the per-lens questions,
and the synthesis protocol live in [references/lenses.md](references/lenses.md).
The altitude engine and the research discipline are shared with `plan-review`
(linked below, not duplicated).

## Rules of engagement (the gate)

Engage only when the work earns several viewpoints.
Apply the gate first and say which side it landed on.

**Engage** when the idea/issue/epic has at least one of:

- it will become an epic, or already is one with child issues
- it spans more than one package/module or a service boundary
- it implies a DB migration, infrastructure change, auth, isolation boundaries, billing, a public API,
  a new secret/env var, or a new dependency
- it has real trade-offs with no obvious right answer, or is hard to reverse once started

**Skip** (say "below threshold — skip", do nothing else) for: a single-file change, a
bugfix/refactor/rename, a dep-bump, docs, or any task that only re-applies an established repo pattern.
One viewpoint is enough there; a panel would be theatre.

## Two ingresses

- **Free text** — a raw idea or brief ("we should let users … / how do we approach …").
  This is the primary case: the output is a *draft* issue/epic, offered for creation only on
  confirmation.
- **Tracker issue/epic** — an existing but under-shaped artifact (`#123`).
  Read its body; for an epic, read each linked child and run the cross-child coherence lens.
  The output rewrites/expands it into a v1 plan.

## Phase 0 — Freeze

Capture the exact artifact under analysis verbatim
(the brief, or the issue/epic body + child set) so it can't drift mid-run.
Record its source (free text, or issue number).
Paste the frozen artifact into each lens prompt so the lenses are independent and grounded on the same
text.

## Phase 1 — Build the senior

Earn the expertise the idea's author lacked, before generating, so the plan is grounded — not guessed.
This is the same research discipline shared with `plan-review`;
the canonical playbook is [research-playbook.md](../plan-review/references/research-playbook.md).

- **Code research (always).**
  Ground in what is true *here*: pinned versions in the repo's lockfile for any dependency in play;
  2–3 existing implementations of the closest analogous feature
  (routing, errors, migrations, tests);
  prior decisions in the repo's instruction files, docs, closed and open issues, revealing commits;
  real constraints (deploy target, CI budget, data shape); blast radius (what imports the surface in
  play).
  Prefer a context-isolated `Explore` subagent for broad sweeps.
  Defer to any project-local skills covering the domain (DB, infra) when present.
- **Web research (on load-bearing decisions only).**
  3–7 dated searches where the world may have moved past the training cutoff
  (deprecations, supersessions, advisories).
  If web is unavailable, tag best-practice claims `[training-data, unverified]`.

## Phase 2 — Fan out the lenses

Run the lenses from [references/lenses.md](references/lenses.md) as **parallel subagents** —
launch them in one batch so they run concurrently and stay blind to each other.
Each receives the frozen artifact, owns one perspective, grounds its claims in the repo
(Phase 1 discipline),
and returns a structured, calibrated result: a one-line stance, what the artifact gets right, findings
(`area — P0|P1|P2|P3 — description — evidence (file:line or issue#/source+date) — concrete fix`),
open questions for humans, and which altitude tests it covers.

Select lenses by proportionality: an infra epic barely needs the product lens; a user-facing feature
leans on it.
Drop or merge a marginal lens and say so — a forced lens produces padding.
For an epic, always add the cross-child coherence lens.

Design each lens to *cover* an altitude test of the shared rubric
(architecture → the interface test; SRE → failure paths + rollback; cost → the quantity test;
security → the threat model and secrets policy; QA → test-first sequencing and test validity),
so the generated plan is born out of the fog on the hard parts.
The altitude engine is shared with `plan-review`:
[review-rubric.md](../plan-review/references/review-rubric.md).
Also derive the repo's own load-bearing conventions (`AGENTS.md`, `CLAUDE.md`, docs) and give each lens
the ones it owns.

## Phase 3 — Synthesise (judge, don't merge)

Combine the lens outputs the way a fusion judge does — compare, don't blend.
Per the protocol in [references/lenses.md](references/lenses.md):

- **Consensus** — what several independent lenses land on is the high-confidence core.
- **Conflicts** — where lenses diverge are the real trade-offs to decide; name them, don't paper over
  them.
- **Blind spots** — what only one lens saw (these are where a panel beats a single reviewer).
- **Findings** — dedup across lenses, on the P0–P3 scale (consequence, not effort).
  Don't inflate.
- **Attack plans** — 2–3 alternative routes with trade-offs (e.g. risk-first, smallest-unblock,
  dependency-ordered), not one default.

Keep the discipline the lenses use: steelman before attacking, concede what holds,
invent no requirements the author never stated (those are open questions for humans).

## Phase 4 — Emit the v1 plan

Write the plan at the right altitude, in the **same shape `plan-review` promotes to** —
so the handoff to it is frictionless:

- **Goal & non-goals** — who it's for, what they can do afterwards, what is explicitly out of scope.
- **Decisions** — each load-bearing choice named (library + pinned version) with a one-line rationale
  and evidence.
- **Design** — detail only where the risk is: the hard interfaces, failure paths, quantities.
  Not the easy parts.
- **Sequencing (test-first)** — smallest useful version first, and for an epic the ordering spans
  children.
  Each step that changes application behaviour names its test *before* the implementation: the test that
  fails today and passes when the step is done, at the level the repo's testing topology assigns, and at
  a named **seam** — the public interface where the behaviour is observed (an exported function, an HTTP
  route, a CLI); a test aimed at internals is implementation-coupled and dies on the next refactor.
  Test-first is per step, not up-front in bulk: a plan that writes all the tests before any
  implementation verifies imagined behaviour.
  The test must be able to fail for the right reason (not a tautology; discriminating; hermetic;
  confirmed by reverting the code under test).
  Bugfix-shaped steps start from the test that reproduces the defect.
  Non-behavioural steps (infra, docs, config) carry their own proportionate verification instead.
- **Risks & rollback** — the hard-to-reverse steps and how to back out; name the rollout mechanism
  (a feature flag, where the repo has a flag system) and the rollback trigger when the change is
  user-facing.
- **Open questions** — product/judgement calls that belong to a human.
  Present them as a numbered **frontier round**: only questions whose prerequisites are already settled
  (one whose answer depends on another open question waits for the next round), each with a one-line
  recommended answer.
  Facts are never questions — anything answerable from the repo or the web is Phase 1 research; only
  decisions go to the human.

## Output

Deliver in chat, always:

1. **Synthesis** — consensus, conflicts, blind spots, findings by severity, attack plans, and a one-line
   handoff: "v1 ready for `plan-review`". plan-well does not issue a build/no-build verdict — that is
   `plan-review`'s call.
2. **v1 plan** — the rewrite above.

For the **tracker** ingress, or when free text should become an epic: after presenting in chat,
offer to create or update the issue/epic
(e.g. `gh issue create` / `gh issue edit <#> --body-file …`, in the repository's language convention,
body via temp file).
Do this **only on explicit confirmation** — never create, edit, comment, or push without it.
Free-text runs that stay exploratory output to chat only.

Read-only otherwise: never edit code, commit, or push.
