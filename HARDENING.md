<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v3.0.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **crowdin--github-action/v3.0.2** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Direct expression interpolation of workflow_dispatch inputs inside run: shell commands. In update-main-version.yml, `${{ github.event.inputs.main_version }}` and `${{ github.event.inputs.target }}` are interpolated directly into git shell commands without going through an env: block or any quoting. An attacker with write access (or a maintainer tricked into running the workflow) could supply shell metacharacters to execute arbitrary commands. Offending lines:
  Line 30: `run: git tag -f ${{ github.event.inputs.main_version }} ${{ github.event.inputs.target }}`
  Line 33: `run: git push origin ${{ github.event.inputs.main_version }} --force`

Locations:

- `.github/workflows/update-main-version.yml:30`
- `.github/workflows/update-main-version.yml:33`

### unpinned-uses (severity: high)

Multiple workflow files reference external actions using mutable version tags instead of pinned 40-character commit SHAs. This exposes the workflow to supply-chain attacks if the referenced tag is moved or the upstream repository is compromised. Failing references:
  - test-action.yml: `actions/checkout@v4`
  - update-main-version.yml: `actions/checkout@v4`
  - lint-pr-title.yml: `amannn/action-semantic-pull-request@v5`

Locations:

- `.github/workflows/test-action.yml:13`
- `.github/workflows/update-main-version.yml:21`
- `.github/workflows/lint-pr-title.yml:14`

### missing-permissions (severity: medium)

None of the three workflow files declare a top-level `permissions:` block, and no job within them declares job-level permissions either. Without explicit permissions, workflows inherit the default repository token permissions (which may be broad, e.g. write access to contents). Affected files: lint-pr-title.yml, test-action.yml, update-main-version.yml.

Locations:

- `.github/workflows/lint-pr-title.yml:1`
- `.github/workflows/test-action.yml:1`
- `.github/workflows/update-main-version.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all three findings across three workflow files: (1) script-injection in update-main-version.yml — moved github.event.inputs.main_version and github.event.inputs.target into env: blocks and referenced them as double-quoted shell variables; (2) unpinned-uses — pinned actions/checkout@v4 to SHA 11d5960a326750d5838078e36cf38b85af677262 in both test-action.yml and update-main-version.yml, and amannn/action-semantic-pull-request@v5 to SHA e32d7e603df1aa1ba07e981f2a23455dee596825 in lint-pr-title.yml; (3) missing-permissions — added top-level permissions blocks: contents:write for update-main-version.yml (needs to push tags), contents:read for test-action.yml, and pull-requests:read for lint-pr-title.yml.

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed all findings in entrypoint.sh:

**script-injection fixes:**
- Changed shebang from #!/bin/sh to #!/bin/bash and added bash to Dockerfile (apk add bash) to enable bash array/xargs idioms
- INPUT_COMMAND is now quoted as "$INPUT_COMMAND" (single value, not a list)
- INPUT_COMMAND_ARGS is tokenized via xargs into positional params using the bash while/read/xargs pattern
- All *_ARGS inputs (INPUT_UPLOAD_SOURCES_ARGS, INPUT_UPLOAD_TRANSLATIONS_ARGS, INPUT_DOWNLOAD_SOURCES_ARGS, INPUT_DOWNLOAD_TRANSLATIONS_ARGS) are tokenized via xargs into local opts() arrays and expanded as "${opts[@]}"
- Replaced string-concatenation OPTIONS variables with bash arrays to prevent word splitting
- --project-id=${INPUT_PROJECT_ID} is now "--project-id=${INPUT_PROJECT_ID}" (quoted)
- INPUT_DOWNLOAD_BUNDLE is now "${INPUT_DOWNLOAD_BUNDLE}" (quoted)
- DOWNLOAD_BUNDLE_ARGS changed from a string to an array and expanded as "${DOWNLOAD_BUNDLE_ARGS[@]}"

**github-env-injection fixes:**
- PULL_REQUESTS_URL sanitized with printf '%s' | tr -d '\n\r' before writing to GITHUB_OUTPUT
- PULL_REQUESTS_NUMBER sanitized with printf '%s' | tr -d '\n\r' before writing to GITHUB_OUTPUT
- CROWDIN_OUTPUT heredoc block sanitized with printf '%s' | tr -d '\r' | grep -v '^CROWDIN_EOF$' to prevent heredoc delimiter injection

