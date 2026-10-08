---
name: workspace-push-access
description: How to push to this workspace repo and to upstream Go from the maintainer's machine (which gh/SSH account has what access)
metadata:
  type: reference
---

Access as of 2026-10-08:
- **This workspace repo** (`redis-performance/hdr-agent-workspace`): `fcostaoliveira` has push; `filipecosta90` does not,
  and the machine's SSH key authenticates as `filipecosta90`, so `git push` over SSH is denied. Push over HTTPS with
  `fcostaoliveira`'s gh token, using a one-off `credential.helper` that prints `username=x-access-token` and the token from
  `gh auth token --user fcostaoliveira`, then `git push https://github.com/redis-performance/hdr-agent-workspace.git HEAD:main`.
  Pushing by URL leaves `origin/main` stale; refresh it with a fetch by URL plus `git update-ref`. Never store the token.
- **Upstream `HdrHistogram/hdrhistogram-go`:** `filipecosta90` is a maintainer (push, releases, workflow dispatch);
  `fcostaoliveira` has pull-only access there, so it can open PRs from its fork but cannot create releases.
- **Fork `fcostaoliveira/hdrhistogram-go`:** push with `fcostaoliveira`'s token over HTTPS, as above.

**How to apply:** commit and push workspace updates after each step ([[push-status-continuously]]); PR and release roles
are in [[go-pr-merge-authority]].
