<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v2.16.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **crowdin--github-action/v2.16.2** was hardened automatically. 0 finding(s) were identified and resolved across 1 iteration(s).

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection, script-injection

**Notes:**

Fixed all findings in entrypoint.sh:

1. github-env-injection: Replaced the static 'CROWDIN_EOF' heredoc delimiter with a randomized delimiter (CROWDIN_EOF_<random-hex> from /dev/urandom) when writing CROWDIN_OUTPUT to $GITHUB_OUTPUT. This prevents an attacker from embedding the delimiter string in command output to break out of the heredoc and inject arbitrary key=value pairs. Switched from echo to printf for reliability.

2. script-injection: Fixed all unquoted $INPUT_* variable expansions:
   - INPUT_COMMAND is now quoted as '"${INPUT_COMMAND}"' in eval
   - INPUT_COMMAND_ARGS uses eval for intentional word-splitting while preventing glob expansion
   - INPUT_DOWNLOAD_BUNDLE is now quoted as '"${INPUT_DOWNLOAD_BUNDLE}"' in eval
   - set -- "$@" ${INPUT_COMMAND_ARGS} changed to eval set -- '"$@"' "$INPUT_COMMAND_ARGS"
   - All *_OPTIONS accumulation variables (UPLOAD_SOURCES_OPTIONS, UPLOAD_TRANSLATIONS_OPTIONS, DOWNLOAD_SOURCES_OPTIONS, DOWNLOAD_TRANSLATIONS_OPTIONS) are now passed via eval with double-quoting, preventing shell metacharacter injection from user-controlled INPUT_*_ARGS values

