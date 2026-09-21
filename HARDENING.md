<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v3.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **crowdin--github-action/v3.0.0** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Direct expression interpolation in run: blocks. In update-main-version.yml, the 'Tag new target' step interpolates ${{ github.event.inputs.main_version }} and ${{ github.event.inputs.target }} directly into a git tag shell command, and the 'Push new tag' step interpolates ${{ github.event.inputs.main_version }} directly into a git push command. These workflow_dispatch inputs are attacker-controllable and can contain shell metacharacters, enabling command injection.

Locations:

- `.github/workflows/update-main-version.yml:30`
- `.github/workflows/update-main-version.yml:33`

### script-injection (severity: high)

Sub-rule (b): Unquoted shell variable expansion of untrusted data in entrypoint.sh. The inherited env vars $INPUT_COMMAND and $INPUT_COMMAND_ARGS (set by the calling workflow) are expanded unquoted in: `crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS` (both in the echo and the command substitution). Similarly, $INPUT_DOWNLOAD_BUNDLE is expanded unquoted in: `crowdin bundle download $INPUT_DOWNLOAD_BUNDLE $DOWNLOAD_BUNDLE_ARGS`. Unquoted expansion allows shell metacharacters (;, |, &, $(...), etc.) in these inputs to be interpreted by the shell.

Locations:

- `entrypoint.sh:338`
- `entrypoint.sh:340`
- `entrypoint.sh:371`

### github-env-injection (severity: high)

In entrypoint.sh, CROWDIN_OUTPUT — derived from running `crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS` where INPUT_COMMAND and INPUT_COMMAND_ARGS are workflow-controlled env vars — is written to $GITHUB_OUTPUT without sanitization (no `printf '%s' ... | tr -d '\n\r'` applied before the write). A malicious command output containing newlines could inject arbitrary key=value pairs into the GitHub output context. The heredoc delimiter (CROWDIN_EOF) mitigates the newline injection for the heredoc block itself, but the unsanitized PULL_REQUESTS_URL and PULL_REQUESTS_NUMBER (from GitHub API responses, which can be influenced by attacker-controlled PR data) are also written directly to $GITHUB_OUTPUT without sanitization.

Locations:

- `entrypoint.sh:343`
- `entrypoint.sh:344`
- `entrypoint.sh:345`
- `entrypoint.sh:296`
- `entrypoint.sh:300`

### unpinned-uses (severity: high)

All three workflow files reference actions by mutable version tags instead of full 40-character commit SHAs, making them vulnerable to supply-chain attacks if the referenced tag is moved or compromised. Failing references: test-action.yml: `actions/checkout@v4`; update-main-version.yml: `actions/checkout@v4`; lint-pr-title.yml: `amannn/action-semantic-pull-request@v5`.

Locations:

- `.github/workflows/test-action.yml:13`
- `.github/workflows/update-main-version.yml:22`
- `.github/workflows/lint-pr-title.yml:14`

### missing-permissions (severity: medium)

None of the three workflow files define a top-level `permissions:` block, and no job within them defines job-level permissions either. Without explicit permissions, workflows inherit the default repository token permissions (which may be write-all depending on repository settings), violating the principle of least privilege. Affected files: test-action.yml, update-main-version.yml, lint-pr-title.yml.

Locations:

- `.github/workflows/test-action.yml:1`
- `.github/workflows/update-main-version.yml:1`
- `.github/workflows/lint-pr-title.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, unpinned-uses, missing-permissions

**Notes:**

Fixed all 5 findings:

1. script-injection (update-main-version.yml): Moved ${{ github.event.inputs.main_version }} and ${{ github.event.inputs.target }} from run: blocks into env: blocks, referenced as double-quoted shell variables.

2. script-injection (entrypoint.sh): Quoted $INPUT_COMMAND as "$INPUT_COMMAND"; tokenized $INPUT_COMMAND_ARGS list via xargs into a bash array and expanded as "${cmd_args[@]}"; quoted $INPUT_DOWNLOAD_BUNDLE as "$INPUT_DOWNLOAD_BUNDLE".

3. github-env-injection (entrypoint.sh): Sanitized PULL_REQUESTS_URL and PULL_REQUESTS_NUMBER with printf '%s' ... | tr -d '\n\r' before writing to $GITHUB_OUTPUT. The CROWDIN_OUTPUT heredoc write already uses a safe CROWDIN_EOF delimiter.

4. unpinned-uses: Pinned actions/checkout@v4 to SHA 11d5960a326750d5838078e36cf38b85af677262 in both test-action.yml and update-main-version.yml; pinned amannn/action-semantic-pull-request@v5 to SHA e32d7e603df1aa1ba07e981f2a23455dee596825 in lint-pr-title.yml.

5. missing-permissions: Added permissions blocks to all three workflow files (contents: read for test-action.yml, contents: write for update-main-version.yml, pull-requests: read for lint-pr-title.yml).

