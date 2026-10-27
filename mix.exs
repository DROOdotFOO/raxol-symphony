defmodule RaxolSymphony.MixProject do
  use Mix.Project

  @version "0.2.1"
  @source_url "https://github.com/DROOdotFOO/raxol-symphony"

  # Frozen per ADR-0043: every raxol package is a git dep pinned to the last
  # DROOdotFOO/raxol commit this package built against.
  @raxol_git "https://github.com/DROOdotFOO/raxol.git"
  @raxol_ref "ce40937c452bf9f076d18e9ff30d8cb645ab3cd6"

  def project do
    [
      app: :raxol_symphony,
      version: @version,
      elixir: "~> 1.17 or ~> 1.18 or ~> 1.19 or ~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs"
      ],
      deps: deps(),
      # cowlib 2.20.0 is the latest release and neither vulnerable function is called; see #921.
      hex: [ignore_advisories: ["EEF-CVE-2026-43966", "EEF-CVE-2026-43969"]],
      description: description(),
      package: package(),
      docs: docs(),
      name: "RaxolSymphony",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      raxol_dep(:raxol_core, "packages/raxol_core"),

      # Main raxol (Lifecycle runtime, Recording for evidence). Compile-time only --
      # runtime: false keeps :raxol out of this package's .app applications list so
      # the host (which owns raxol) controls its boot, avoiding circular OTP startup.
      raxol_dep(:raxol, nil, optional: true, runtime: false),

      # Agent runner backend. Optional at compile time so the orchestrator core
      # can be exercised in tests with a noop runner.
      raxol_dep(:raxol_agent, "packages/raxol_agent", optional: true),

      # raxol_earn is pulled in test env ONLY to exercise the canonical
      # cross-package auto-resume flow (Job.Server transition telemetry ->
      # Resumer -> Orchestrator.resume_run). Symphony does not depend on
      # ACP at runtime or compile time outside tests.
      raxol_dep(:raxol_earn, "packages/raxol_earn", only: :test),

      # MCP surface (optional).
      raxol_dep(:raxol_mcp, "packages/raxol_mcp", optional: true),

      # LiveView/Telegram/Watch surfaces -- all optional, gated at runtime.
      raxol_dep(:raxol_liveview, "packages/raxol_liveview", optional: true),
      raxol_dep(:raxol_telegram, "packages/raxol_telegram", optional: true),
      raxol_dep(:raxol_watch, "packages/raxol_watch", optional: true),

      # Transitive raxol packages. Their own mix.exs files name siblings by
      # relative path, which a sparse checkout lacks, so each is pinned here.
      raxol_dep(:raxol_terminal, "packages/raxol_terminal", optional: true),
      raxol_dep(:raxol_sensor, "packages/raxol_sensor", optional: true),
      raxol_dep(:raxol_plugin, "packages/raxol_plugin", optional: true),
      raxol_dep(:raxol_agent_client_protocol, "packages/raxol_agent_client_protocol",
        optional: true
      ),
      raxol_dep(:raxol_web3, "packages/raxol_web3", optional: true),
      raxol_dep(:raxol_payments, "packages/raxol_payments", only: :test),

      # YAML front matter parsing.
      {:yaml_elixir, "~> 2.12"},

      # Liquid template rendering for prompt body.
      {:solid, "~> 0.18", optional: true},

      # File watcher for hot-reloading WORKFLOW.md.
      {:file_system, "~> 1.1", optional: true},

      # JSON
      {:jason, "~> 1.4"},

      # HTTP client for tracker adapters.
      {:req, "~> 0.5", optional: true},

      # PostgreSQL driver for the paused-runs Postgrex saver. Optional;
      # consumers must add :postgrex and supervise a connection.
      {:postgrex, "~> 0.17", optional: true},

      # Web surface deps: both optional, since the JSON API and the
      # LiveView dashboard are gated at compile time on these being loaded.
      {:plug, "~> 1.14", optional: true},
      {:phoenix_live_view, "~> 1.0 or ~> 0.20", optional: true},

      # Dev/test only
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp raxol_dep(name, sparse, opts \\ []) do
    git = [git: @raxol_git, ref: @raxol_ref, depth: 1, override: true]
    git = if sparse, do: Keyword.put(git, :sparse, sparse), else: git
    {name, Keyword.merge(git, opts)}
  end

  defp description do
    """
    OpenAI Symphony port for Raxol. Polls an issue tracker, isolates each
    issue in a per-issue workspace, and runs a coding agent (raxol_agent or
    Codex) until the work reaches a workflow-defined handoff state. Surfaces
    runs across terminal, LiveView, MCP, Telegram, and Watch.
    """
  end

  defp package do
    [
      name: "raxol_symphony",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Docs" => "https://hexdocs.pm/raxol_symphony",
        "Changelog" => "https://github.com/DROOdotFOO/raxol-symphony/blob/main/CHANGELOG.md"
      },
      maintainers: ["Raxol Team"],
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md CHANGELOG.md)
    ]
  end

  # Package-scoped tag, not `v#{@version}`: the bare `vX.Y.Z` tags belong to
  # the root `raxol` version line, and `v0.2.0` there is raxol from 2025. A
  # bare tag would point every source link in these docs at unrelated code.
  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "raxol_symphony-v#{@version}",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
