<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v2.16.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **crowdin--github-action/v2.16.2** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Two `run:` steps in update-main-version.yml directly interpolate `${{ github.event.inputs.main_version }}` and `${{ github.event.inputs.target }}` into shell commands without routing through env vars. This allows an attacker with workflow_dispatch access to inject arbitrary shell commands. Offending lines:
- `run: git tag -f ${{ github.event.inputs.main_version }} ${{ github.event.inputs.target }}` (sub-rule a)
- `run: git push origin ${{ github.event.inputs.main_version }} --force` (sub-rule a)

Locations:

- `.github/workflows/update-main-version.yml:30`
- `.github/workflows/update-main-version.yml:33`

### unpinned-uses (severity: high)

Multiple workflow files reference external actions by mutable tag instead of a full 40-character commit SHA, making them vulnerable to supply-chain attacks if the tag is moved:
- `amannn/action-semantic-pull-request@v5` in lint-pr-title.yml
- `actions/checkout@v4` in test-action.yml
- `actions/checkout@v4` in update-main-version.yml

Locations:

- `.github/workflows/lint-pr-title.yml:13`
- `.github/workflows/test-action.yml:9`
- `.github/workflows/update-main-version.yml:20`

### missing-permissions (severity: medium)

None of the three workflow files declare a top-level `permissions:` key, and no job within them declares job-level permissions either. Without explicit permissions, workflows inherit the default repository token permissions (which may be broad), violating the principle of least privilege.

Locations:

- `.github/workflows/lint-pr-title.yml:1`
- `.github/workflows/test-action.yml:1`
- `.github/workflows/update-main-version.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all three findings across the three workflow files:

1. script-injection: Moved `${{ github.event.inputs.main_version }}` and `${{ github.event.inputs.target }}` out of `run:` shell strings into `env:` blocks in update-main-version.yml. Shell commands now reference plain env vars ($MAIN_VERSION, $TARGET) instead of interpolating expressions directly.

2. unpinned-uses: Pinned all three action references to full 40-char SHAs — `amannn/action-semantic-pull-request@e32d7e603df1aa1ba07e981f2a23455dee596825 # v5` and `actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4` (used in both test-action.yml and update-main-version.yml).

3. missing-permissions: Added top-level `permissions:` blocks to all three files with least-privilege grants: `pull-requests: read` for lint-pr-title.yml, `contents: read` for test-action.yml, and `contents: write` for update-main-version.yml (required to push tags).

