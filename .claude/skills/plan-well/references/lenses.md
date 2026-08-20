# Lenses and synthesis

Reference for Phase 2 (fan-out) and Phase 3 (synthesis) of `plan-well`.
The lenses are *generative* perspectives:
each one proposes how to approach the work from its angle and names the risks it sees.
The synthesis then compares them — consensus, conflicts, blind spots — the way a fusion judge compares a
panel, without blending the answers into mush.

## The lenses

Each lens is a parallel subagent.
Give it the frozen artifact, its perspective, and the discipline below.
Each lens is built to *cover* one or more altitude tests of the shared rubric,
so the generated plan is born already out of the fog on the hard parts.

### Product / PM

- **Owns:** who this is for, what they can do afterwards they couldn't before, the smallest slice that
  delivers value, what to cut.
  For an internal/infra epic this often reduces to "what does this unblock, in what order" —
  say so rather than forcing a user story.
- **Grounding:** the goal statement, prior product decisions, who actually consumes the outcome.
- **Covers:** audience test, success test, non-goals test.

### Architecture / Engineering

- **Owns:** the design, the boundaries between packages/services, the shape of the load-bearing
  interfaces, how the pieces compose, ownership contracts between this work and its dependencies.
- **Grounding:** the closest analogous implementation in the repo, the dependency graph / blast radius,
  pinned versions, existing conventions the design must match or justify breaking.
- **Covers:** interface test, named-technology test, proportionality.

### Security / Compliance

- **Owns:** threat model, attack surface, secrets handling per the repo's policy (where secrets live,
  how they reach runtime/CI, never in plaintext config or logs), isolation boundaries (multi-tenancy,
  sandboxing), supply chain, who can bypass the controls.
- **Grounding:** the sensitive surfaces in play, how secrets reach the runtime/CI, existing auth and
  isolation patterns, dated advisories on load-bearing choices.
- **Covers:** security/threat-model, isolation and secrets conventions, named-technology.

### Operability / SRE / Delivery

- **Owns:** how it ships and rolls back, blast radius, what happens when each external interaction
  fails, observability, the operational single-points-of-failure.
- **Grounding:** deploy/rollback paths and runbooks, failure modes of the changed surface, real
  quantities (rates, sizes, budgets).
- **Covers:** failure test, quantity test, sequencing, risks & rollback.

### QA / Test

- **Owns:** how success is verified at the right altitude, which suite owns which behaviour,
  determinism, test-first sequencing (each behavioural step names its failing test before the
  implementation; bugfixes start from a reproducing test), and whether a stated check can actually fail
  for the right reason (not a tautology; discriminating; hermetic).
- **Grounding:** the repo's testing guidelines and topology, existing suites, what is and isn't covered.
- **Covers:** success test / test-validity, failure test, sequencing (test-first), proportionality.

### Cost / Efficiency

- **Owns:** the money and time the approach spends — CI minutes, LLM/token cost, infra spend, developer
  wall-clock — quantified, not adjectives.
- **Grounding:** current usage and limits, the marginal cost the change adds, pricing checked with a
  dated source.
- **Covers:** quantity test, proportionality.

### Devil's advocate

- **Owns:** the case against.
  Is it over-scoped?
  What is the smallest shippable that gets 80% of the value?
  Hidden or circular dependencies?
  Work hiding behind "later/eventually/minimal/just"?
  Is a fancy approach gold-plating for the current scale?
- **Grounding:** the real state of the bottleneck dependencies (read them), how far the current state is
  from the goal.
- **Covers:** alternative test, sequencing, proportionality, the vague-word blacklist.

### Cross-child coherence (epic axis — conditional)

Run only when the artifact is an epic with child issues.
Children can each be fine alone and fail as a set.

- **Owns:** **coverage** (do the children together reach the goal?
  any slice no child owns?), **gaps**
  (implied work — migration, rollout, docs, the unhappy path — owned by no issue),
  **overlap** (two children on the same surface), **sequencing**
  (a dependency order with a smallest shippable first, with the implicit edges named),
  **boundary altitude** (is the hardest child itself fog?).
- **Grounding:** read each child via the tracker; record state, scope, owner, and the real dependency
  edges.
- **Covers:** coverage, sequencing, proportionality.

## Lens discipline

Hold every lens to the same bar — a panel that only finds problems is noise, not signal:

- **Steelman first.**
  State the strongest case for a choice before attacking it; if you can't,
  you don't understand it well enough to reject it.
- **Concede what holds.**
  Record "what the artifact gets right" with the same care as faults.
- **Severity is consequence, not effort.**
  P0 (fails as written) · P1 (must fix before building) · P2 (works but meaningfully worse / misfit) ·
  P3 (polish).
  A one-line change can be a P0.
- **Evidence or it's a question.**
  Every finding carries `file:line` or source+date and a concrete fix.
  A finding without a fix is an open question for a human, not a finding.
- **Invent no requirements.**
  A constraint the author never stated is an open question, not a finding.
- **Don't inflate.**
  Three real P0/P1s read as a serious pass; ten padded ones read as noise.

## The lens prompt

Each subagent gets, in one prompt: a note that this is a read-only generative pass
(no edits, no tracker writes);
the **frozen artifact verbatim**; its lens, with the questions it owns; a grounding mandate
(cite real `file:line` / `issue#`, conclusions not file dumps, a tight budget); and the output contract
below.
Launch all lenses in a single batch so they run concurrently and independently.

Output contract per lens:

- **Stance** — one line.
- **What the artifact gets right** — 1–3 points with evidence.
- **Findings** — `area — P0|P1|P2|P3 — description — evidence — concrete fix`.
- **Open questions for humans.**
- **Rubric tests covered.**

## Synthesis protocol

Compare the lens outputs; do not concatenate them.
Produce:

1. **Consensus** — points several independent lenses reached.
   Note *how many* lenses converged: convergence is the confidence signal (the high-confidence core of
   the plan).
2. **Conflicts** — where lenses diverge.
   These are the real trade-offs; present each as a decision for the owner, with the competing readings.
   Two lenses reading the same fact oppositely is often two true axes, not a contradiction — say what
   each captures.
3. **Blind spots** — findings only one lens raised.
   Call them out explicitly; this is where the panel earns its cost over a single reviewer.
4. **Consolidated findings** — dedup across lenses, grouped by P0–P3.
   Same fix mentioned by several lenses collapses to one finding citing them.
5. **Attack plans** — 2–3 alternative routes synthesised across lenses (not from any single one), each
   with its trade-off: e.g. correctness-first (re-baseline before planning), smallest-unblock,
   dependency-ordered.

Then write the v1 plan (Phase 4).
End with the handoff line, never a build verdict.

## Calibration note

The test of a good run is a *good* artifact: on a plan already written at the right altitude,
the panel should mostly confirm it and surface a few real residual conflicts and blind spots — not
rewrite it.
If the synthesis is all rewrite and no consensus, the lenses are padding; if it's all consensus and no
blind spots, the panel was redundant.
Tune lens selection (proportionality) until each lens earns its place.
