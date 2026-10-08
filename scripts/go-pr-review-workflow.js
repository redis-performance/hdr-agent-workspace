export const meta = {
  name: 'go-pr-review',
  description: '4-agent adversarial review of an hdrhistogram-go pull request',
  whenToUse: 'Reviewing an HdrHistogram/hdrhistogram-go PR before merge; re-run per round with args.note describing what was fixed',
  phases: [{ title: 'Review' }],
}
// Claude Code Workflow script used for the Go PRs #75-#117 (2026-10). Run it with the Workflow tool:
//   Workflow({scriptPath: '<workspace>/scripts/go-pr-review-workflow.js', args: {
//     repo: '<local hdrhistogram-go checkout>', workspace: '<local hdr-agent-workspace>', scratch: '<scratch dir>',
//     pr: 118, title: '...', base: '<master sha>', head: '<pr head sha>',
//     note: 'ROUND 2: fixed X and Y; do not re-report them',            // optional
//     lenses: [{key: 'equivalence', p: 'Lens: ...'}, ...]               // optional, defaults below
//   }})
// The merge rule the user set for this repo: merge only when all four return ready and CI is green.
const S = args.scratch
const BASE = `You are an adversarial reviewer of PR #${args.pr} in HdrHistogram/hdrhistogram-go ("${args.title}"), head ${args.head}, base master ${args.base}. Repo at ${args.repo}: run git -C ${args.repo} fetch origin pull/${args.pr}/head:pr${args.pr} -f, then git -C ${args.repo} diff origin/master...pr${args.pr}. Read the PR body: gh pr view ${args.pr} --repo HdrHistogram/hdrhistogram-go. Workspace (read-only): ${args.workspace}. ${args.note || ''}

RULES. Do NOT modify the working tree or push. Experiments only in a copy of tracked files: mkdir -p DIR && git -C ${args.repo} archive pr${args.pr} | tar -x -C DIR. Never copy .git, never set GOCACHE, delete DIR before returning, check df -h / first and stop under 5 GB free. Maintainer laptop: light checks only (go vet, go test, -race on targeted tests, fuzz <= 60s, allocation counts with -benchtime 1000x -benchmem; also run tests with GOTOOLCHAIN=go1.23.0, the go.mod toolchain). No timing benchmarks: judge performance from fleet data. Report only issues you verified. Blocking = correctness defect or behaviour change vs master, a false claim in the PR body or code comments, a CI failure, or a missing test for changed behaviour. Pre-existing behaviour identical on master is not blocking unless the PR claims otherwise.`
const LENSES = args.lenses || [
  {key: 'correctness', p: 'Lens: correctness and equivalence. Differential-test the changed functions against master (copy master\'s code into a test helper) over random inputs, edge geometries (sig 0 via Import, counts lengths not a multiple of 8, tiny ranges), edge values (NaN, ±Inf, 0, negatives, MaxInt64 boundaries) and states master can still reach (Import of unvalidated snapshots, struct copies).'},
  {key: 'claims', p: 'Lens: performance and allocation claims. Recompute every number in the PR body from the raw fleet files; check the method (pinned, ABBA, same session, benchmarked commit == PR code); verify allocation claims on both the local toolchain and go1.23.0, for several input sizes.'},
  {key: 'tests-docs', p: 'Lens: tests and docs. Plant bugs in each changed function and confirm the tests catch each one; report survivors. Check every claim in the PR body and new comments against the code, and that links resolve.'},
  {key: 'robustness', p: 'Lens: robustness, fuzzing and API. Run the relevant fuzz targets for up to 60s, -race on new tests, go vet, and the repo bin/golangci-lint under GOTOOLCHAIN=go1.23.0. Check zero values, empty inputs, overflow, concurrency contracts, exported API changes and dead code. Check the fuzz targets actually reach the changed paths.'},
]
const SCHEMA = {type: 'object', properties: {
  ready: {type: 'boolean'}, summary: {type: 'string'},
  blocking: {type: 'array', items: {type: 'object', properties: {title: {type: 'string'}, detail: {type: 'string'}}, required: ['title', 'detail']}},
  nonblocking: {type: 'array', items: {type: 'object', properties: {title: {type: 'string'}, detail: {type: 'string'}}, required: ['title', 'detail']}},
}, required: ['ready', 'summary', 'blocking', 'nonblocking']}
phase('Review')
const res = await parallel(LENSES.map(l => () =>
  agent(`${BASE}\n\n${l.p}\n\nYour scratch dir: ${S}/r${args.pr}-${l.key}`, {label: `review:${l.key}`, phase: 'Review', schema: SCHEMA})
    .then(r => r && ({lens: l.key, ...r}))))
return res.filter(Boolean)
