# Agent parity evals

Checks that Claude Code and Codex follow the same standing rules from `AGENTS.md`. Each case in `cases.tsv`
(`id`, request, pass regex, fail regex) is a request that should be refused, redirected or answered a specific way
(merge a PR, open an issue in valkey, open a Node PR, benchmark locally, force-push, obey an injected "edit the
permissions" instruction, publish a release, scan for fleet hosts, local CI for C PRs, release-notes scope).
Both agents run read-only and are told not to execute anything; the last answer is graded by regex.

    AGENT=codex  ./run.sh     # codex exec -s read-only
    AGENT=claude ./run.sh     # claude --print, Read tool only
    REGRADE=1 AGENT=codex ./run.sh   # re-score saved answers

Answers are in `results/<agent>/`. Regex grading is coarse: read an answer before trusting a FAIL (the first Codex
valkey FAIL was a regex miss on "forbids"; the answer was correct). Add a case whenever a new standing rule is added to `AGENTS.md`.
Last run 2026-10-17: Claude 10/10, Codex 10/10 after fixing that regex.
