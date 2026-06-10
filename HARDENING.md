<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v2.15.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **crowdin--github-action/v2.15.2** was hardened automatically. 0 finding(s) were identified and resolved across 1 iteration(s).

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed all 7 script-injection locations and 1 github-env-injection location in entrypoint.sh:

1. upload_sources(): Quoted $UPLOAD_SOURCES_OPTIONS → "$UPLOAD_SOURCES_OPTIONS"
2. upload_translations(): Quoted $UPLOAD_TRANSLATIONS_OPTIONS → "$UPLOAD_TRANSLATIONS_OPTIONS"
3. download_sources(): Quoted $DOWNLOAD_SOURCES_OPTIONS → "$DOWNLOAD_SOURCES_OPTIONS"
4. download_translations(): Quoted $DOWNLOAD_TRANSLATIONS_OPTIONS → "$DOWNLOAD_TRANSLATIONS_OPTIONS"
5. INPUT_COMMAND block: Quoted $INPUT_COMMAND → "$INPUT_COMMAND" and $INPUT_COMMAND_ARGS → "$INPUT_COMMAND_ARGS"
6. GITHUB_OUTPUT write: Added sanitization via safe_output=$(printf '%s' "$CROWDIN_OUTPUT" | tr -d '\r') and used printf '%s\n' "$safe_output" to write the value, preventing newline injection
7. bundle download: Quoted $INPUT_DOWNLOAD_BUNDLE → "$INPUT_DOWNLOAD_BUNDLE" and $DOWNLOAD_BUNDLE_ARGS → "$DOWNLOAD_BUNDLE_ARGS"

