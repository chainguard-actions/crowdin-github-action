<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v3.0.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **crowdin--github-action/v3.0.1** was hardened automatically. 4 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (a): Direct expression interpolation of user-controlled workflow_dispatch inputs inside run: shell commands. In update-main-version.yml, `${{ github.event.inputs.main_version }}` and `${{ github.event.inputs.target }}` are interpolated directly into git shell commands. An attacker with permission to trigger the workflow can inject arbitrary shell commands via these inputs. Offending lines:
  Line 30: `run: git tag -f ${{ github.event.inputs.main_version }} ${{ github.event.inputs.target }}`
  Line 33: `run: git push origin ${{ github.event.inputs.main_version }} --force`

Locations:

- `.github/workflows/update-main-version.yml:30`
- `.github/workflows/update-main-version.yml:33`

### unpinned-uses (severity: high)

Multiple workflow files reference external actions using mutable version tags instead of pinned 40-character SHA commit hashes, making them vulnerable to supply-chain attacks if the tag is moved:
  - test-action.yml: `uses: actions/checkout@v4`
  - update-main-version.yml: `uses: actions/checkout@v4`
  - lint-pr-title.yml: `uses: amannn/action-semantic-pull-request@v5`

Locations:

- `.github/workflows/test-action.yml:13`
- `.github/workflows/update-main-version.yml:21`
- `.github/workflows/lint-pr-title.yml:15`

### missing-permissions (severity: medium)

None of the three workflow files define a top-level `permissions:` key, and no job within them defines job-level permissions either. Without explicit permissions, workflows run with the default (potentially broad) token permissions. All three files are affected: lint-pr-title.yml, test-action.yml, and update-main-version.yml.

Locations:

- `.github/workflows/lint-pr-title.yml:1`
- `.github/workflows/test-action.yml:1`
- `.github/workflows/update-main-version.yml:1`

### github-env-injection (severity: high)

In entrypoint.sh, caller-controlled data is written to $GITHUB_OUTPUT without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`):

(1) Lines ~327-329: `CROWDIN_OUTPUT` is the result of executing `crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS`, where `INPUT_COMMAND` and `INPUT_COMMAND_ARGS` are caller-supplied action inputs. This output is written to $GITHUB_OUTPUT via heredoc without newline sanitization, allowing a malicious Crowdin CLI response or crafted input to inject additional key=value pairs into the output file.

(2) Lines ~240-243: `PULL_REQUESTS_URL` and `PULL_REQUESTS_NUMBER` are extracted from the GitHub API JSON response (which may contain attacker-influenced data such as PR branch names or titles) and written directly to $GITHUB_OUTPUT without sanitization.

Locations:

- `entrypoint.sh:327`
- `entrypoint.sh:240`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, unpinned-uses, missing-permissions, github-env-injection

**Notes:**

Fixed all four findings:

1. script-injection (update-main-version.yml lines 30, 33): Moved `${{ github.event.inputs.main_version }}` and `${{ github.event.inputs.target }}` into `env:` blocks as MAIN_VERSION and TARGET, then referenced them as shell variables in the run commands.

2. unpinned-uses: Pinned actions/checkout@v4 to SHA 11d5960a326750d5838078e36cf38b85af677262 in both test-action.yml and update-main-version.yml; pinned amannn/action-semantic-pull-request@v5 to SHA e32d7e603df1aa1ba07e981f2a23455dee596825 in lint-pr-title.yml.

3. missing-permissions: Added `permissions: contents: write` to update-main-version.yml (needs to push tags), `permissions: contents: read` to test-action.yml, and `permissions: pull-requests: read` to lint-pr-title.yml.

4. github-env-injection (entrypoint.sh): (a) Sanitized PULL_REQUESTS_URL and PULL_REQUESTS_NUMBER with `printf '%s' | tr -d '\n\r'` before writing to $GITHUB_OUTPUT. (b) Replaced static heredoc delimiter CROWDIN_EOF with a random hex value from `openssl rand -hex 16` to prevent injection via a crafted delimiter line in the Crowdin CLI output.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed all unquoted shell variable expansions of user-controlled inputs in entrypoint.sh:

1. **upload_sources()** (line 25): Replaced unquoted `$UPLOAD_SOURCES_OPTIONS` with a bash array tokenized via xargs (`upload_sources_opts`), then expanded as `"${upload_sources_opts[@]}"`.

2. **upload_translations()** (line 47): Same fix for `$UPLOAD_TRANSLATIONS_OPTIONS` → `upload_translations_opts` array.

3. **download_sources()**: Same fix for `$DOWNLOAD_SOURCES_OPTIONS` → `download_sources_opts` array.

4. **download_translations()**: Same fix for `$DOWNLOAD_TRANSLATIONS_OPTIONS` → `download_translations_opts` array.

5. **INPUT_COMMAND_ARGS in set --** (pre-line 356): Replaced `set -- "$@" ${INPUT_COMMAND_ARGS}` with a while/xargs loop that adds each tokenized argument individually to positional params.

6. **DOWNLOAD_BUNDLE_ARGS** (line 356 area): Changed from scalar `DOWNLOAD_BUNDLE_ARGS="$@"` to array `DOWNLOAD_BUNDLE_ARGS=("$@")` and updated usage to `"${DOWNLOAD_BUNDLE_ARGS[@]}"`.

7. **INPUT_COMMAND / INPUT_COMMAND_ARGS execution** (lines 356-359): Replaced `crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS` with properly tokenized arrays `cmd_tokens` and `cmd_args_tokens` built via xargs, then expanded as `crowdin "${cmd_tokens[@]}" "${cmd_args_tokens[@]}"`.

8. **INPUT_DOWNLOAD_BUNDLE** (line 395): Replaced unquoted `$INPUT_DOWNLOAD_BUNDLE` with a `bundle_id_tokens` array built via xargs.

9. Updated shebang from `#!/bin/sh` to `#!/bin/bash` since the script already used bash-specific features (`[[ ]]`, arrays, process substitution) and the new fixes also require bash.

The `echo "RUNNING COMMAND crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS"` line remains as-is since it's inside double quotes (preventing word-splitting/glob) and is only used for logging, not command execution.

