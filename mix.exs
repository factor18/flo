defmodule Flo.MixProject do
  use Mix.Project

  def project do
    [
      app: :flo,
      deps: deps(),
      docs: docs(),
      version: "0.2.0",
      elixir: "~> 1.11",
      package: package(),
      description: description(),
      start_permanent: Mix.env() == :prod
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Flo.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2"},
      {:solid, "~> 0.8"},
      {:construct, "~> 2.1"},
      {:libgraph, "~> 0.13.3"},
      {:accessible, "~> 0.3.0"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:luerl, git: "https://github.com/rvirding/luerl.git", branch: "develop"}
    ]
  end

  defp docs do
    [
      main: "Flo",
      extras: ["README.md"],
      groups_for_modules: [
        components: [
          Flo.Core.Component.Log,
          Flo.Core.Component.Delay
        ],
        triggers: [
          Flo.Core.Trigger.Interval
        ]
      ]
    ]
  end

  defp package() do
    [
      licenses: ["Apache 2.0"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      links: %{"GitHub" => "https://github.com/factor18/flo"}
    ]
  end

  defp description do
    "Extensible workflow orchestration framework"
  end
end
