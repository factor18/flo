defmodule Virta.MixProject do
  use Mix.Project

  def project do
    [
      app: :virta,
      deps: deps(),
      docs: docs(),
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: { Virta, [] },
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libgraph, "~> 0.7"},
      {:poolboy, "~> 1.5.1"},
      {:ex_doc, "~> 0.18.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "Virta",
      extras: ["README.md"],
      groups_for_modules: [
        "Components": [Virta.Core.In, Virta.Core.Out, Virta.Core.Workflow],
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib","test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
