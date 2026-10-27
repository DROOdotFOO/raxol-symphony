# Raxol Symphony

> **Frozen 2026-10-27 per ADR-0043 Decision 6: unpublished, CI off, pinned to
> raxol `ce40937c4`; returns only as a Hex consumer of both repos.** History
> was extracted from `packages/raxol_symphony` in
> [DROOdotFOO/raxol](https://github.com/DROOdotFOO/raxol) with `git filter-repo`.
> Every raxol package is a git dependency pinned to that commit (see `mix.exs`).
> **Dependencies are frozen with known advisories (e.g. plug_crypto
> EEF-CVE-2026-105963); not for live use.**

A Raxol port of [OpenAI Symphony](https://github.com/openai/symphony): an
orchestrator that turns tracker work into autonomous coding-agent runs. Each
issue gets an isolated workspace, runs an agent until the work reaches a
workflow-defined handoff state, and surfaces evidence (CI/PR/walkthrough) so
engineers manage outcomes rather than prompts.

Implements [`SPEC.md`](https://github.com/openai/symphony/blob/main/SPEC.md).

## Status

Version 0.2.1, never published to Hex. At the freeze, `MIX_ENV=test mix test`
passed 1101 tests (23 doctests, 1078 tests). Two runner backends ship:
`raxol_agent` (default, wraps `Raxol.Agent.Stream`) and `codex app-server`
(Port-based JSON-RPC for parity with upstream Symphony Elixir). Three
workflow modes: `default` (inline), `graph` (per-node checkpointed
pipeline), and `graph_parallel` (batches eligible issues into one fan-out
run per tick). Six surfaces (terminal dashboard, LiveView, MCP, Telegram,
Watch, JSON API). Evidence collection (CI status, PR comments, complexity,
asciinema replays) ships per run. The live graduation run in
[`RUNBOOK.md`](RUNBOOK.md) was never captured. The feature guide is
[`docs/SYMPHONY.md`](docs/SYMPHONY.md).

## Trust posture

Designed for trusted developer-machine deployments. The default `raxol_agent`
runner uses `CommandHook` + `PermissionHook` to deny shell operations outside
the per-issue workspace. See `SPEC.md` s15 for hardening guidance.
