# Plan review rubric

Reference for Phase 2 (altitude diagnosis) and Phase 3 (adversarial review) of `plan-review`.
`plan-well`'s lenses are built to cover the same tests, so a generated v1 is born against this rubric.

## Altitude diagnostics

Classify each section independently.
A plan is usually **mixed**: fogged on the hard parts, tunneled on the easy ones —
because the author wrote detail where comfortable and abstraction where not.
That inversion (detail on easy parts, fog on hard parts) is itself a finding.

### Fog tests (too vague)

Run against every component, step, or workstream the plan names.
Each "no" is a finding.

1. **Start-tomorrow test** — could a competent engineer begin this item tomorrow without making an
   architecture or product decision themselves?
   If they'd have to choose a library, design a schema, or define an API first, the plan didn't plan it.
2. **Interface test** — does anything crossing a boundary
   (function, service, queue, file, network) have its shape written down?
   Field names, not "the relevant data".
3. **Failure test** — for each external interaction
   (network, disk, user input, third-party API), does the plan say what happens when it fails?
   "Handle errors" is not an answer.
4. **Quantity test** — are load-bearing quantities stated?
   Row counts, payload sizes, request rates, latency budgets.
   "Should be fast" is fog.
5. **Named-technology test** — is every "a cache / a queue / some auth layer" either named (with version)
   or listed as an open decision with candidates?

### Tunnel tests (too granular / missing vision)

Run against the artifact as a whole.
Each "no" is a finding.

1. **Audience test** — does the plan say who this is for and what they can do afterward that they
   couldn't before?
2. **Success test** — is there an observable definition of success?
   A metric, demo, passing suite, user behavior.
   When success is "a test passes", the test must be able to fail for the right reason:
   a plan whose success criterion is a test that would be a tautology
   (exercises the harness, not production code), non-discriminating
   (passes for a collateral reason even with the protection removed), or non-hermetic
   (depends on a live external service)
   has defined no success at all — catch it here, before the code is written, not at diff review.
3. **Non-goals test** — is anything explicitly out of scope?
   A plan with no non-goals was described, not scoped.
4. **Alternative test** — does the plan say why this approach beat the obvious boring alternative?
   No alternative considered = the choice was a default, not a decision.
5. **Sequencing test** — is there an ordering with a smallest useful version first, or a flat list of
   equal tasks?
   And do the behavioural steps name their failing test before the implementation (test-first), rather
   than a trailing "add tests"?
6. **Proportionality test** — does detail land where the risk is?
   Twenty lines on a helper and one on the data migration means the plan is upside down.

## Vague-word blacklist

When these appear without immediate quantification, challenge them with the concrete question they hide
from:

| Word | Hidden question |
|---|---|
| simple / straightforward | Simple compared to what? What did you not have to handle? |
| scalable | To what number, on what axis, measured how? |
| robust / resilient | Against which specific failures? What is the recovery path? |
| handle gracefully | What exactly happens? Retry, drop, queue, surface to user? |
| performant / fast | What latency/throughput budget, at what percentile? |
| secure | Against which threat model? Who is the attacker? |
| flexible / extensible | For which anticipated change? Flexibility has a cost — who pays it? |
| later / eventually / for now | A sequencing decision or an unowned risk? Who reopens it, triggered by what? |
| etc. / and so on | The list was the work. Finish it. |
| appropriate / as needed | By whose judgment, applied when? |
| leverage / utilize | Usually decorating an undecided choice. Name the thing. |

## Severity (P0–P3)

Severity = consequence, not effort-to-fix.

- **P0** — the plan fails as written.
  Targets an API the pinned dependency version lacks; contradicts a settled repo decision without
  acknowledging it; omits a migration the change requires; relies on a pattern with a published security
  advisory; an entire hard component is fog (fails the start-tomorrow test).
- **P1** — must fix before building.
  A load-bearing interface or failure path is undefined; no rollback story for a hard-to-reverse step
  (migration, deploy, production data); an isolation-scoped surface (multi-tenant data, sandboxed
  execution) with no isolation story.
- **P2** — works but meaningfully worse than the state of the art or misfit to the repo.
  Hand-rolls something a maintained installed dependency provides; uses a pattern superseded since
  cutoff (with source); inverted proportionality; success criteria exist but aren't observable;
  behavioural steps sequenced implementation-first with tests as an afterthought.
- **P3** — polish.
  Naming, doc gaps, small idiom mismatches, ordering tweaks that reduce risk but don't change outcome.

Calibration:

- Every finding carries evidence (`file:line`, or source + date) and a concrete fix.
  A finding without a fix is a question — put it in "Open questions for humans".
- Don't inflate.
  Three real P0/P1s read as a serious review; ten padded ones read as noise and get ignored.
- Don't self-defer.
  Report every surviving finding at its severity; never downgrade or drop a P1/P2 because it "could be a
  follow-up" — deferral is the plan owner's call, not the reviewer's.
  Let the verdict stand on the surviving findings.
- Track "What the plan got right" with the same care as faults.
  The promoted plan must preserve it, and the user needs to see the review is calibrated, not
  performatively hostile.

## Adversarial discipline

- **Steelman first.**
  Before attacking a choice, state the strongest case for it in one or two sentences.
  If you can't, you don't understand it well enough to reject it.
- **Attack the artifact, not the author.**
  Findings name the text's failure, not the author's.
- **Concede when beaten.**
  If research validates the choice, say so and move on.
  A review that can never return "this holds" is a ritual, not a review.
- **One altitude per finding.**
  Don't bundle "this is vague" with "this library is outdated" — different fixes.
- **No invented requirements.**
  A constraint the user never stated ("must support 1M users") is an open question for the human, not a
  finding.
