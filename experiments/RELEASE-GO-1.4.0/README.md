# hdrhistogram-go 1.4.0 release preparation (2026-10-08)

- `RELEASE-NOTES-v1.4.0.md`: the draft release body (house format of v1.3.0, plus the chart and a behaviour-change table). It cites 16 of the 17
  PRs merged since v1.3.0 (`687f303`): #83 (README only) is left out as a documentation change.
- Chart: `../GO-BENCH-1.3.0-VS-TIP-186f8b9-2026-10-08/charts/speedup.png`, embedded by a commit-pinned raw URL of this repository (HTTP 200, `image/png`).
  Same two-step as the C 0.12.0 release: once happy, copy it into the Go repo (`docs/images/1.4.0/`) by a docs PR and repoint the URL at that merge commit.
- The version number `v1.4.0` is an assumption (v1.3.0 is already published; the release adds API and changes behaviour). Change it in the notes and the command if needed.

## Create the draft (needs push access on HdrHistogram/hdrhistogram-go; the agent account has pull only)

    gh release create v1.4.0 -R HdrHistogram/hdrhistogram-go --draft --target master \
      --title "Version 1.4.0" --notes-file experiments/RELEASE-GO-1.4.0/RELEASE-NOTES-v1.4.0.md

Run it from a checkout of this repository (gh needs the notes file inside the working repository). `--target` can be the exact commit instead of `master`.

## Not done before publishing

- **#117** was merged ahead of its fleet re-measurement (random-write cost on `PackedHistogram` unmeasured on the final code); the notes make no number claim for it.
- **Re-fuzz the final tip** on the fleet: the 6-hour run covered `de66007`, before #108, #109, #112, #114, #115, #116, #117.
- **ARM64 `FuzzPackedDifferential` failure** (fork run 37628119727) is unexplained; the input does not reproduce.
- `PackedHistogram` memory figures are quoted from the text of #75, not re-measured here.
