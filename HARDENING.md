<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v3.0.0-next.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **crowdin--github-action/v3.0.0-next.1** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Multiple workflow files reference actions using mutable version tags instead of pinned full-length SHA commit hashes, making them vulnerable to supply-chain attacks if the tag is moved.

- `.github/workflows/lint-pr-title.yml`: `uses: amannn/action-semantic-pull-request@v5` (mutable tag)
- `.github/workflows/test-action.yml`: `uses: actions/checkout@v4` (mutable tag)
- `.github/workflows/update-main-version.yml`: `uses: actions/checkout@v4` (mutable tag)

All should be pinned to a full 40-character commit SHA, e.g. `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4`.

Locations:

- `.github/workflows/lint-pr-title.yml:12`
- `.github/workflows/test-action.yml:13`
- `.github/workflows/update-main-version.yml:20`

### script-injection (severity: high)

In `.github/workflows/update-main-version.yml`, two `run:` steps directly interpolate `${{ github.event.inputs.main_version }}` and `${{ github.event.inputs.target }}` (workflow_dispatch user-controlled inputs) into shell commands without routing through environment variables. This allows an attacker with workflow_dispatch access to inject arbitrary shell commands.

Violating lines (sub-rule a — direct expression interpolation in run: block):
- Line 30: `run: git tag -f ${{ github.event.inputs.main_version }} ${{ github.event.inputs.target }}`
- Line 33: `run: git push origin ${{ github.event.inputs.main_version }} --force`

Fix: move the values into `env:` variables and double-quote their expansions in the shell script.

Locations:

- `.github/workflows/update-main-version.yml:30`
- `.github/workflows/update-main-version.yml:33`

### permissions (severity: medium)

None of the three workflow files define a top-level `permissions:` block, and no job within them defines job-level permissions either. This means workflows run with the default (potentially broad) token permissions.

- `.github/workflows/lint-pr-title.yml`: No permissions defined. This file uses the `pull_request_target` trigger, which runs with write access to the base repository — the absence of a minimal permissions block is especially dangerous here.
- `.github/workflows/test-action.yml`: No permissions defined.
- `.github/workflows/update-main-version.yml`: No permissions defined.

Each workflow should declare a top-level `permissions:` block with the minimum required scopes (e.g. `contents: read`).

Locations:

- `.github/workflows/lint-pr-title.yml:1`
- `.github/workflows/test-action.yml:1`
- `.github/workflows/update-main-version.yml:1`

### github-env-injection (severity: high)

In `entrypoint.sh`, the `$INPUT_COMMAND` and `$INPUT_COMMAND_ARGS` environment variables (inherited from the calling workflow and therefore untrusted) are passed unsanitized to `crowdin`, and the resulting output (`$CROWDIN_OUTPUT`) is written to `$GITHUB_OUTPUT` without the required `printf '%s' ... | tr -d '\n\r'` sanitization step. If the Crowdin CLI echoes back any part of the input arguments containing newline characters, an attacker could inject arbitrary key=value pairs into the GitHub Actions output context.

Offending block (around line 337 of entrypoint.sh):
```sh
CROWDIN_OUTPUT=$(crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS)
...
echo "command_output<<CROWDIN_EOF" >> $GITHUB_OUTPUT
echo "$CROWDIN_OUTPUT" >> $GITHUB_OUTPUT
echo "CROWDIN_EOF" >> $GITHUB_OUTPUT
```

Additionally, `$PULL_REQUESTS_URL` and `$PULL_REQUESTS_NUMBER` (derived from an external API response) are written to `$GITHUB_OUTPUT` without sanitization, which could allow a malicious API response to inject additional output variables.

All values written to `$GITHUB_OUTPUT`, `$GITHUB_ENV`, or `$GITHUB_PATH` should be sanitized with `printf '%s' "$VAR" | tr -d '\n\r'` before the write.

Locations:

- `entrypoint.sh:337`
- `entrypoint.sh:143`
- `entrypoint.sh:147`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, permissions, github-env-injection

**Notes:**

Fixed all four findings:

1. **unpinned-uses**: Pinned all action references to full SHA hashes:
   - `amannn/action-semantic-pull-request@e32d7e603df1aa1ba07e981f2a23455dee596825 # v5` in lint-pr-title.yml
   - `actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4` in both test-action.yml and update-main-version.yml

2. **script-injection**: In update-main-version.yml, moved `${{ github.event.inputs.main_version }}` and `${{ github.event.inputs.target }}` into `env:` blocks (as `MAIN_VERSION` and `TARGET`) and referenced them as double-quoted shell variables.

3. **permissions**: Added top-level `permissions:` blocks to all three workflows:
   - lint-pr-title.yml: `pull-requests: read` + `statuses: write`
   - test-action.yml: `contents: read`
   - update-main-version.yml: `contents: write` (required to push tags)

4. **github-env-injection**: In entrypoint.sh, sanitized `PULL_REQUESTS_URL` and `PULL_REQUESTS_NUMBER` with `printf '%s' "$VAR" | tr -d '\n\r'` before writing to `$GITHUB_OUTPUT`, and sanitized `CROWDIN_OUTPUT` with `printf '%s' "$CROWDIN_OUTPUT" | tr -d '\r'` before the heredoc write (preserving newlines for multiline output while stripping carriage returns that could enable injection).

