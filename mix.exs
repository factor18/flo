defmodule Virta.MixProject do
  use Mix.Project

  def project do
    [
      app: :virta,
      deps: deps(),
      docs: docs(),
      version: "1.0.0",
      elixir: "~> 1.11",
      package: package(),
      description: description(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Virta.Application, []},
    ]
  end

  defp deps do
    [
      {:poison, "~> 3.1"},
      {:libgraph, "~> 0.13.3"},
    ]
  end

  defp docs do
    [
      main: "Virta",
      extras: ["README.md"],
    ]
  end

  defp package() do
    [
      licenses: ["Apache 2.0"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      links: %{"GitHub" => "https://github.com/sarat1669/virta"}
    ]
  end

  defp description do
    "Ecosystem for event-driven applications"
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
