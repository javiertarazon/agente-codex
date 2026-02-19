---
name: merge-pr
description: Script-first deterministic squash merge with strict required-check gating, head-SHA pinning, and reliable attribution/commenting.
---

# Merge PR

## Overview

Merge a prepared PR only after deterministic validation.

## Inputs

- Ask for PR number or URL.
- If missing, use `.local/prep.env` from the PR worktree.

## Safety

- Never use `gh pr merge --auto` in this flow.
- Never run `git push` directly.
- Require `--match-head-commit` during merge.

## Execution Contract

1. Validate merge readiness:

```sh
scripts/pr-merge verify <PR>
```

2. Run one-shot deterministic merge:

```sh
scripts/pr-merge run <PR>
```

3. Ensure output reports:

- `merge_sha=<sha>`
- `merge_author_email=<email>`
- `comment_url=<url>`

## Steps

1. Validate artifacts

```sh
require=(.local/review.md .local/review.json .local/prep.md .local/prep.env)
for f in "${require[@]}"; do
  [ -s "$f" ] || { echo "Missing artifact: $f"; exit 1; }
done
```

2. Validate checks and branch status

```sh
scripts/pr-merge verify <PR>
source .local/prep.env
```

3. Merge deterministically

```sh
scripts/pr-merge run <PR>
```

This performs:
- deterministic squash merge pinned to `PREP_HEAD_SHA`
- co-author trailers for PR author and reviewer
- post-merge verification of co-author trailers
- PR comment retry (3 attempts)
- cleanup after confirmed `MERGED`

## Go/No-Go Checklist Before Merge

- All BLOCKER and IMPORTANT findings are resolved.
- Changelog is updated (mandatory).
- Required CI checks are green.
- Branch is not behind `main`.

## Guardrails

- End in `MERGED`, never `CLOSED`.
- Cleanup only after confirmed merge.

## Workflow completo

Ver [PR_WORKFLOW.md](../PR_WORKFLOW.md) para el flujo completo review → prepare → merge.
