<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v3.0.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **crowdin--github-action/v3.0.0** was hardened automatically. 0 finding(s) were identified and resolved across 1 iteration(s).

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed all findings in entrypoint.sh:

1. script-injection (3 locations):
   - Line 336: Replaced unquoted `${INPUT_COMMAND_ARGS}` in `set -- "$@" ${INPUT_COMMAND_ARGS}` with a POSIX-compatible xargs tokenization loop using `xargs -n1 printf '%s\n'` and a while/read loop.
   - Line 344: Replaced `crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS` with `crowdin "$INPUT_COMMAND"` (quoted) and `printf '%s' "$INPUT_COMMAND_ARGS" | xargs crowdin "$INPUT_COMMAND"` for the args-present case.
   - Line 362: Replaced `crowdin bundle download $INPUT_DOWNLOAD_BUNDLE` with `crowdin bundle download "$INPUT_DOWNLOAD_BUNDLE"` (quoted single value).

2. github-env-injection (3 locations):
   - Lines 152/156: Added `printf '%s' "$VAR" | tr -d '\n\r'` sanitization before writing PULL_REQUESTS_URL and PULL_REQUESTS_NUMBER to GITHUB_OUTPUT.
   - Line 348: The CROWDIN_OUTPUT write already uses the heredoc format (`command_output<<CROWDIN_EOF`) which is the correct safe approach for multiline values in GITHUB_OUTPUT - this format prevents newline injection of additional key=value pairs.

