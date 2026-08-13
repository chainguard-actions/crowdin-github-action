<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v3.0.0-next.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **crowdin--github-action/v3.0.0-next.3** was hardened automatically. 4 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (a): Two `run:` steps in update-main-version.yml directly interpolate `${{ github.event.inputs.main_version }}` and `${{ github.event.inputs.target }}` (workflow_dispatch user inputs) into shell commands without any env-var indirection or quoting. This allows an authorized caller to inject arbitrary shell metacharacters into `git tag` and `git push` commands. Offending lines:
  - `run: git tag -f ${{ github.event.inputs.main_version }} ${{ github.event.inputs.target }}`
  - `run: git push origin ${{ github.event.inputs.main_version }} --force`

Locations:

- `.github/workflows/update-main-version.yml:28`
- `.github/workflows/update-main-version.yml:31`

### unpinned-uses (severity: high)

Multiple workflow files reference actions using mutable version tags instead of pinned 40-character commit SHAs, making them vulnerable to supply-chain attacks if the tag is moved:
  - `amannn/action-semantic-pull-request@v5` (lint-pr-title.yml)
  - `actions/checkout@v4` (test-action.yml)
  - `actions/checkout@v4` (update-main-version.yml)

Locations:

- `.github/workflows/lint-pr-title.yml:14`
- `.github/workflows/test-action.yml:13`
- `.github/workflows/update-main-version.yml:20`

### missing-permissions (severity: medium)

None of the three workflow files define a top-level `permissions:` block, and no job within them defines job-level `permissions:` either. Without explicit permissions, workflows run with the default (potentially broad) token permissions, violating the principle of least privilege.

Locations:

- `.github/workflows/lint-pr-title.yml:1`
- `.github/workflows/test-action.yml:1`
- `.github/workflows/update-main-version.yml:1`

### github-env-injection (severity: high)

entrypoint.sh writes several values derived from external/caller-controlled sources to $GITHUB_OUTPUT without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`):

1. `PULL_REQUESTS_URL` and `PULL_REQUESTS_NUMBER` are extracted from GitHub API responses (which can contain attacker-controlled content such as PR branch names) via `jq` and written directly to $GITHUB_OUTPUT:
   - `echo "pull_request_url=$PULL_REQUESTS_URL" >> $GITHUB_OUTPUT`
   - `echo "pull_request_number=$PULL_REQUESTS_NUMBER" >> $GITHUB_OUTPUT`

2. `CROWDIN_OUTPUT` is the stdout of `crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS` where `INPUT_COMMAND` and `INPUT_COMMAND_ARGS` are caller-supplied action inputs. This output is written to $GITHUB_OUTPUT using a heredoc, but the heredoc delimiter itself (`CROWDIN_EOF`) could be spoofed if the command output contains that string, and the value is not sanitized before writing:
   - `echo "command_output<<CROWDIN_EOF" >> $GITHUB_OUTPUT`
   - `echo "$CROWDIN_OUTPUT" >> $GITHUB_OUTPUT`

Locations:

- `entrypoint.sh:12`
- `entrypoint.sh:148`
- `entrypoint.sh:151`
- `entrypoint.sh:345`
- `entrypoint.sh:347`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, unpinned-uses, missing-permissions, github-env-injection

**Notes:**

Fixed all four findings:
1. script-injection (update-main-version.yml lines 28,31): Moved `${{ github.event.inputs.main_version }}` and `${{ github.event.inputs.target }}` into `env:` blocks; shell commands now reference `"$MAIN_VERSION"` and `"$TARGET"` safely.
2. unpinned-uses: Pinned actions/checkout@v4 to SHA 11d5960a326750d5838078e36cf38b85af677262 (in test-action.yml and update-main-version.yml) and amannn/action-semantic-pull-request@v5 to SHA e32d7e603df1aa1ba07e981f2a23455dee596825 (in lint-pr-title.yml).
3. missing-permissions: Added top-level `permissions:` blocks to all three workflow files with minimal required permissions (pull-requests: read, contents: read, contents: write respectively).
4. github-env-injection (entrypoint.sh): Sanitized PULL_REQUESTS_URL and PULL_REQUESTS_NUMBER with `tr -d '\n\r'` before writing to $GITHUB_OUTPUT; replaced fixed heredoc delimiter `CROWDIN_EOF` with a random hex value from `openssl rand -hex 16` to prevent delimiter injection.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed all 5 script-injection findings in entrypoint.sh:

1. INPUT_PROJECT_ID (line 213): Quoted the flag+value as a single word: `"--project-id=${INPUT_PROJECT_ID}"`.

2. INPUT_COMMAND_ARGS in set -- (line 228): Replaced unquoted `${INPUT_COMMAND_ARGS}` expansion with an xargs-based tokenization loop that safely splits the args list into individually quoted positional parameters.

3. INPUT_COMMAND and INPUT_COMMAND_ARGS in crowdin command (line 248): Quoted `"$INPUT_COMMAND"` and built a `cmd_args` array via xargs tokenization, expanded as `"${cmd_args[@]}"`.

4. INPUT_DOWNLOAD_BUNDLE (line 265): Quoted `"$INPUT_DOWNLOAD_BUNDLE"` and converted DOWNLOAD_BUNDLE_ARGS from a plain string to a bash array `DOWNLOAD_BUNDLE_ARGS=("$@")`, expanded as `"${DOWNLOAD_BUNDLE_ARGS[@]}"`.

5. UPLOAD_SOURCES_OPTIONS, UPLOAD_TRANSLATIONS_OPTIONS, DOWNLOAD_SOURCES_OPTIONS, DOWNLOAD_TRANSLATIONS_OPTIONS (lines 25, 47, 57, 82): Replaced all string-based *_OPTIONS variables with properly typed bash arrays. User-controlled *_ARGS inputs are tokenized via xargs (with guard conditions) and appended to these arrays. Arrays are expanded as `"${array[@]}"` in all crowdin command invocations, preventing word-splitting and shell metacharacter injection.

