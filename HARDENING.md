<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v2.17.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **crowdin--github-action/v2.17.1** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Direct expression interpolation in run: blocks. In update-main-version.yml, workflow_dispatch inputs are interpolated directly into shell commands without going through env: variables. `run: git tag -f ${{ github.event.inputs.main_version }} ${{ github.event.inputs.target }}` and `run: git push origin ${{ github.event.inputs.main_version }} --force` allow an attacker with workflow_dispatch access to inject arbitrary shell commands via the `target` or `main_version` inputs.

Locations:

- `.github/workflows/update-main-version.yml:30`
- `.github/workflows/update-main-version.yml:33`

### unpinned-uses (severity: high)

Multiple workflow files reference actions by mutable version tags instead of full 40-character commit SHAs, making them vulnerable to supply-chain attacks if the tag is moved. Failing references: `amannn/action-semantic-pull-request@v5` (lint-pr-title.yml), `actions/checkout@v4` (test-action.yml), `actions/checkout@v4` (update-main-version.yml).

Locations:

- `.github/workflows/lint-pr-title.yml:14`
- `.github/workflows/test-action.yml:9`
- `.github/workflows/update-main-version.yml:20`

### missing-permissions (severity: medium)

None of the three workflow files define a top-level `permissions:` block, and no job within them defines job-level permissions either. Without explicit permissions, workflows run with the default (potentially broad) token permissions. Affected files: lint-pr-title.yml (uses pull_request_target trigger, making broad permissions especially risky), test-action.yml, and update-main-version.yml.

Locations:

- `.github/workflows/lint-pr-title.yml:1`
- `.github/workflows/test-action.yml:1`
- `.github/workflows/update-main-version.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all three findings across .github/workflows/update-main-version.yml, .github/workflows/lint-pr-title.yml, and .github/workflows/test-action.yml:

1. script-injection: Moved github.event.inputs.main_version and github.event.inputs.target into env: blocks in update-main-version.yml; shell commands now use $MAIN_VERSION and $TARGET environment variables.

2. unpinned-uses: Pinned amannn/action-semantic-pull-request@v5 to @e32d7e603df1aa1ba07e981f2a23455dee596825 and actions/checkout@v4 to @11d5960a326750d5838078e36cf38b85af677262 in all affected files.

3. missing-permissions: Added top-level permissions blocks — lint-pr-title.yml gets pull-requests:read + statuses:write; test-action.yml gets contents:read; update-main-version.yml gets contents:write (required to push tags).

### Iteration 2

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed all 7 script-injection locations and 3 github-env-injection locations in entrypoint.sh:

**Script injection fixes:**
- Lines 30/51/60/87: Replaced unquoted `$UPLOAD_SOURCES_OPTIONS`, `$UPLOAD_TRANSLATIONS_OPTIONS`, `$DOWNLOAD_SOURCES_OPTIONS`, `$DOWNLOAD_TRANSLATIONS_OPTIONS` expansions with xargs-tokenized bash arrays (guarded with `if [ -n "$VAR" ]` to prevent empty-value issues).
- Line 330: Replaced `set -- "$@" ${INPUT_COMMAND_ARGS}` with xargs tokenization into `command_args_tokens` array.
- Line 345: Replaced `crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS` with `crowdin "$INPUT_COMMAND" "${crowdin_cmd_args[@]}"` where args are xargs-tokenized.
- Line 375: Replaced `crowdin bundle download $INPUT_DOWNLOAD_BUNDLE $DOWNLOAD_BUNDLE_ARGS` with `crowdin bundle download "$INPUT_DOWNLOAD_BUNDLE" "${DOWNLOAD_BUNDLE_ARGS[@]}"` and changed `DOWNLOAD_BUNDLE_ARGS` from a string to an array assignment `DOWNLOAD_BUNDLE_ARGS=("$@")`.

**GitHub env injection fixes:**
- Lines 155/159: Added `printf '%s' "$VAR" | tr -d '\n\r'` sanitization for `PULL_REQUESTS_URL` and `PULL_REQUESTS_NUMBER` before writing to `$GITHUB_OUTPUT`.
- Line 349: Sanitized `CROWDIN_OUTPUT` by stripping lines matching the heredoc delimiter `CROWDIN_EOF` to prevent delimiter injection.

**Shebang fix:** Changed `#!/bin/sh` to `#!/bin/bash` since the script already used bash-specific `[[ ]]` syntax and now also requires bash arrays and process substitution.

