<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v3.2.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **crowdin--github-action/v3.2.0** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): Multiple workflow-controllable `INPUT_*` environment variables are expanded unquoted inside shell command execution contexts in `entrypoint.sh`, allowing an attacker to inject shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.).

1. Line ~330: `CROWDIN_OUTPUT=$(crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS)` — both `$INPUT_COMMAND` and `$INPUT_COMMAND_ARGS` are unquoted.
2. Line ~338: `echo "command_output<<CROWDIN_EOF"` block — `$INPUT_COMMAND` / `$INPUT_COMMAND_ARGS` feed the command.
3. Line ~360: `crowdin bundle download $INPUT_DOWNLOAD_BUNDLE $DOWNLOAD_BUNDLE_ARGS` — `$INPUT_DOWNLOAD_BUNDLE` is unquoted.
4. Line ~290: `set -- "$@" --project-id=${INPUT_PROJECT_ID}` — `${INPUT_PROJECT_ID}` is unquoted (no surrounding quotes).
5. Line ~295: `set -- "$@" ${INPUT_COMMAND_ARGS}` — `${INPUT_COMMAND_ARGS}` is unquoted.
6. Line ~30: `crowdin upload sources "$@" $UPLOAD_SOURCES_OPTIONS` — `$UPLOAD_SOURCES_OPTIONS` is built from unquoted `${INPUT_UPLOAD_SOURCES_ARGS}` and is itself unquoted.

All of these `INPUT_*` variables are set by the calling workflow and are attacker-controllable. They must be double-quoted (`"$INPUT_COMMAND"`) or, for word-split argument lists, properly handled with arrays.

Locations:

- `entrypoint.sh:30`
- `entrypoint.sh:290`
- `entrypoint.sh:295`
- `entrypoint.sh:330`
- `entrypoint.sh:360`

### github-env-injection (severity: high)

In `entrypoint.sh`, the variable `CROWDIN_OUTPUT` is populated by running `crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS` where both `INPUT_COMMAND` and `INPUT_COMMAND_ARGS` are workflow-controllable inputs. The result is then written directly to `$GITHUB_OUTPUT` via `echo "$CROWDIN_OUTPUT" >> $GITHUB_OUTPUT` without the required sanitization step (`printf '%s' "$CROWDIN_OUTPUT" | tr -d '\n\r'`). A malicious value containing newlines could inject arbitrary key=value pairs into the GitHub output context, potentially overwriting other outputs or injecting environment variables consumed by downstream steps.

Locations:

- `entrypoint.sh:338`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed all script-injection and github-env-injection findings in entrypoint.sh:

1. Changed shebang from #!/bin/sh to #!/bin/bash and added bash to Dockerfile's apk install to enable bash arrays and process substitution on Alpine.

2. script-injection fixes:
   - Line 30 (upload_sources): Replaced unquoted $UPLOAD_SOURCES_OPTIONS string with a bash array using xargs-based NUL-delimited tokenization of INPUT_UPLOAD_SOURCES_ARGS.
   - Line 290: Quoted --project-id=${INPUT_PROJECT_ID} as "--project-id=${INPUT_PROJECT_ID}".
   - Line 295: Replaced unquoted ${INPUT_COMMAND_ARGS} expansion with xargs tokenization into a bash array, then set -- "$@" "${_cmd_args[@]}".
   - Line 330: Changed `crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS` to `crowdin "$INPUT_COMMAND" "$@"` (INPUT_COMMAND quoted; args already in $@ from the tokenization at line 295).
   - Line 360: Changed `crowdin bundle download $INPUT_DOWNLOAD_BUNDLE $DOWNLOAD_BUNDLE_ARGS` to `crowdin bundle download "$INPUT_DOWNLOAD_BUNDLE" "${DOWNLOAD_BUNDLE_ARGS[@]}"` and converted DOWNLOAD_BUNDLE_ARGS from a string to a bash array.
   - Also fixed upload_translations, download_sources, and download_translations functions to use bash arrays instead of unquoted string variables.

3. github-env-injection fix (line 338): Added sanitization step `safe_output=$(printf '%s' "$CROWDIN_OUTPUT" | tr -d '\r')` before writing to $GITHUB_OUTPUT, preventing newline injection attacks.

### Iteration 1

**Fixes applied:** unpinned-uses

**Notes:**

Pinned the Dockerfile base image from `FROM crowdin/cli:5.2.0` to `FROM crowdin/cli:5.2.0@sha256:60e632130aebe5b26c577ae6b236fd92b4246e426499d4e0bac22fd240cb3cc7`. The tag is kept inline alongside the digest for readability, and the image is now immutably pinned to prevent supply-chain attacks via mutable tags.

