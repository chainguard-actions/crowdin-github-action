<!-- markdownlint-disable -->

# Hardening Report: crowdin--github-action/v3.6.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **crowdin--github-action/v3.6.0** was hardened automatically. 0 finding(s) were identified and resolved across 1 iteration(s).

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

entrypoint.sh: the multi-line command_output write used the fixed heredoc delimiter CROWDIN_EOF. It now uses a delimiter built on every run from 16 bytes of /dev/urandom read with od, which is POSIX sh compatible. The value goes through as is, line breaks included, and $GITHUB_OUTPUT is now quoted. Not run or tested.

