<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v3.4.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **crowdin--github-action/v3.4.0** was hardened automatically. 0 finding(s) were identified and resolved across 1 iteration(s).

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed all script-injection and github-env-injection findings in entrypoint.sh:

1. script-injection: Converted entrypoint.sh from #!/bin/sh to #!/bin/bash (added bash to Dockerfile via apk add). Replaced all unquoted $UPLOAD_SOURCES_OPTIONS, $UPLOAD_TRANSLATIONS_OPTIONS, $DOWNLOAD_SOURCES_OPTIONS, $DOWNLOAD_TRANSLATIONS_OPTIONS string variables with bash arrays in each function (local caller_args=("$@") + local extra_args=()). User-provided *_ARGS inputs are tokenized via xargs into arrays. Fixed --project-id=${INPUT_PROJECT_ID} to "--project-id=${INPUT_PROJECT_ID}". Fixed ${INPUT_COMMAND_ARGS} in set -- to use xargs tokenization into COMMAND_ARGS array. Fixed CROWDIN_OUTPUT=$(crowdin $INPUT_COMMAND $INPUT_COMMAND_ARGS) to use quoted variables. Fixed crowdin bundle download to use quoted "${INPUT_DOWNLOAD_BUNDLE}" and array "${DOWNLOAD_BUNDLE_ARGS[@]}".

2. github-env-injection: Sanitized PULL_REQUESTS_URL and PULL_REQUESTS_NUMBER with printf '%s' ... | tr -d '\n\r' before writing to $GITHUB_OUTPUT. Left the CROWDIN_OUTPUT heredoc form unchanged (heredoc with fixed delimiter already prevents injection per the rules).

