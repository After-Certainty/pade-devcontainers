# Experiment 004 — required, optional, and unsupported demand

**Status:** Implemented in this PR; GitHub CI evidence pending.

## Question

After Runtime Conditions trust/validation has already accepted a Profile, how does the current `rc-pade` platform-support boundary distinguish:

1. supported required demand;
2. supported optional demand;
3. unsupported required demand;
4. unsupported optional demand?

## Method

The experiment uses the same source-control Condition shape for every case.

Two Profiles differ only in `optional`:

- required: `optional` omitted / false;
- optional: `optional: true`.

Two operator policies differ only in platform support:

- supported policy explicitly maps `source_control/git` GitHub fetch to `github.repo.read`;
- unsupported policy contains no mapping for `source_control/git`.

This isolates **platform mapping support** from the Profile's trust/validation status.

## Expected current behavior

| Demand | Current expected result |
|---|---|
| supported + required | bind succeeds; DevelopmentSession requests `github.repo.read` with `required: true` |
| supported + optional | bind succeeds; DevelopmentSession requests `github.repo.read` with `required: false` |
| unsupported + required | bind fails closed; local bindings remain empty |
| unsupported + optional | bind also fails closed; local bindings remain empty |

The fourth row is an **architectural finding**, not a declaration that optional unsupported demand should normatively fail.

Current rc-pade performs top-level policy matching before optionality affects the projected capability, so an unmapped optional Condition has no separate continue/report path.

## Why this matters

This preserves the distinction between facts and desired semantics:

```text
RC validity/trust
    ≠
platform support
    ≠
capability requiredness
    ≠
broker authorization
```

The experiment should tell us what the current reusable boundary actually does before we decide whether optional-but-unsupported demand needs a new result model or adapter behavior.

## CI proof

CI builds the pinned rc-pade revision and requires all four observations above.

For both unsupported cases it also pre-populates stale local state and requires failure to leave mode-`0600` `capabilities: {}`.

## Claim boundary

These checked-in Profiles represent the **post-trust** input boundary. This experiment does not run the RC validator and therefore does not independently establish validator acceptance.

A future semantic change for optional unsupported demand belongs in the appropriate RC / rc-pade contract discussion, not as hidden behavior in pade-devcontainers.
