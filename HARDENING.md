<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v2.15.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **crowdin--github-action/v2.15.2** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a) violation: Two `run:` steps in update-main-version.yml directly interpolate `${{ github.event.inputs.main_version }}` and `${{ github.event.inputs.target }}` — both workflow_dispatch user-controlled inputs — directly inside shell command strings. An attacker with permission to trigger the workflow can inject arbitrary shell commands. Offending lines:
  - `run: git tag -f ${{ github.event.inputs.main_version }} ${{ github.event.inputs.target }}`
  - `run: git push origin ${{ github.event.inputs.main_version }} --force`
Fix: move the values into `env:` variables and reference them as quoted `"$VAR"` in the shell.

Locations:

- `.github/workflows/update-main-version.yml:27`
- `.github/workflows/update-main-version.yml:30`

### unpinned-uses (severity: high)

Multiple workflow files reference external actions using mutable version tags instead of pinned 40-character commit SHAs, making them vulnerable to supply-chain attacks if the tag is moved:
  - `.github/workflows/lint-pr-title.yml`: `uses: amannn/action-semantic-pull-request@v5`
  - `.github/workflows/test-action.yml`: `uses: actions/checkout@v4`
  - `.github/workflows/update-main-version.yml`: `uses: actions/checkout@v4`
Fix: pin each reference to a full SHA, e.g. `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4`.

Locations:

- `.github/workflows/lint-pr-title.yml:13`
- `.github/workflows/test-action.yml:13`
- `.github/workflows/update-main-version.yml:19`

### missing-permissions (severity: medium)

None of the three workflow files declare a top-level `permissions:` block, and no job within them declares job-level permissions either. Without explicit permissions, workflows receive the repository's default token permissions (often `write-all`), violating the principle of least privilege.
  - `.github/workflows/lint-pr-title.yml` — triggered on `pull_request_target` (elevated risk)
  - `.github/workflows/test-action.yml`
  - `.github/workflows/update-main-version.yml`
Fix: add a top-level `permissions:` block with only the scopes each workflow actually needs.

Locations:

- `.github/workflows/lint-pr-title.yml:1`
- `.github/workflows/test-action.yml:1`
- `.github/workflows/update-main-version.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all three findings across three workflow files:

1. script-injection (update-main-version.yml): Moved `${{ github.event.inputs.main_version }}` and `${{ github.event.inputs.target }}` from inline shell strings into `env:` blocks, referencing them as quoted `"$MAIN_VERSION"` and `"$TARGET"` in the run commands.

2. unpinned-uses: Pinned all three mutable tag references to full commit SHAs:
   - amannn/action-semantic-pull-request@v5 → @e32d7e603df1aa1ba07e981f2a23455dee596825 # v5
   - actions/checkout@v4 → @11d5960a326750d5838078e36cf38b85af677262 # v4 (both occurrences)

3. missing-permissions: Added top-level `permissions:` blocks with least-privilege scopes:
   - lint-pr-title.yml: pull-requests: read
   - test-action.yml: contents: read
   - update-main-version.yml: contents: write

