<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v3.0.0-next.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **crowdin--github-action/v3.0.0-next.0** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

In .github/workflows/update-main-version.yml, two run: steps directly interpolate workflow_dispatch user-controlled inputs inside shell commands. The 'Tag new target' step runs: `git tag -f ${{ github.event.inputs.main_version }} ${{ github.event.inputs.target }}` and the 'Push new tag' step runs: `git push origin ${{ github.event.inputs.main_version }} --force`. Both violate sub-rule (a): ${{ ... }} expressions interpolated directly in a run: block allow YAML template substitution to inject arbitrary shell metacharacters before the shell parses the command.

Locations:

- `.github/workflows/update-main-version.yml:29`
- `.github/workflows/update-main-version.yml:32`

### unpinned-uses (severity: high)

Multiple workflow files reference external actions using mutable version tags instead of pinned 40-character commit SHAs, making them vulnerable to supply-chain attacks. Failing references: lint-pr-title.yml uses `amannn/action-semantic-pull-request@v5`; test-action.yml uses `actions/checkout@v4`; update-main-version.yml uses `actions/checkout@v4`.

Locations:

- `.github/workflows/lint-pr-title.yml:14`
- `.github/workflows/test-action.yml:13`
- `.github/workflows/update-main-version.yml:21`

### missing-permissions (severity: medium)

None of the three workflow files define a top-level permissions: key, and no job within any of these files defines a job-level permissions: key. Without explicit permissions, workflows run with default GitHub token permissions which may be overly broad (e.g., write access to contents and pull-requests). Affected files: lint-pr-title.yml (triggered by pull_request_target, making this especially risky), test-action.yml, and update-main-version.yml.

Locations:

- `.github/workflows/lint-pr-title.yml:1`
- `.github/workflows/test-action.yml:1`
- `.github/workflows/update-main-version.yml:1`

### github-env-injection (severity: high)

In entrypoint.sh (the Docker action entrypoint), inherited process environment variables from the calling workflow are written to $GITHUB_OUTPUT without the required sanitization step (printf '%s' ... | tr -d '\n\r'). (1) $INPUT_COMMAND and $INPUT_COMMAND_ARGS are workflow-controlled env vars used unquoted in `crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS`; the captured output $CROWDIN_OUTPUT is then written directly to $GITHUB_OUTPUT via heredoc without newline sanitization, enabling a newline-injection attack on the output file. (2) $INPUT_DOWNLOAD_BUNDLE is used unquoted in `crowdin bundle download $INPUT_DOWNLOAD_BUNDLE $DOWNLOAD_BUNDLE_ARGS`. All these writes lack the mandatory sanitization before >> $GITHUB_OUTPUT.

Locations:

- `entrypoint.sh:338`
- `entrypoint.sh:375`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, unpinned-uses, missing-permissions, github-env-injection

**Notes:**

Fixed all four findings:
1. script-injection (update-main-version.yml lines 29,32): Moved ${{ github.event.inputs.main_version }} and ${{ github.event.inputs.target }} into env: blocks (MAIN_VERSION, TARGET) and referenced as double-quoted shell variables.
2. unpinned-uses: Pinned actions/checkout@v4 to SHA 11d5960a326750d5838078e36cf38b85af677262 in both test-action.yml and update-main-version.yml; pinned amannn/action-semantic-pull-request@v5 to SHA e32d7e603df1aa1ba07e981f2a23455dee596825 in lint-pr-title.yml.
3. missing-permissions: Added top-level permissions blocks to all three workflow files (lint-pr-title.yml: pull-requests:read + statuses:read; test-action.yml: contents:read; update-main-version.yml: contents:write).
4. github-env-injection (entrypoint.sh lines 338,375): Quoted $INPUT_COMMAND in crowdin invocation; sanitized CROWDIN_OUTPUT with tr -d '\r' before writing to $GITHUB_OUTPUT using printf-based heredoc; quoted $INPUT_DOWNLOAD_BUNDLE in bundle download command.

