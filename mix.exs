defmodule Virta.MixProject do
  use Mix.Project

  def project do
    [
      app: :virta,
      deps: deps(),
      docs: docs(),
      version: "0.1.2",
      elixir: "~> 1.6",
      package: package(),
      description: description(),
      build_embedded: Mix.env == :prod,
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

  defp package() do
    [
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/sarat1669/virta"}
    ]
  end

  defp description do
    "Flow based programming for elixir"
  end

  defp elixirc_paths(:test), do: ["lib","test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
