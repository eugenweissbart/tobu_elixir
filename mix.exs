defmodule Tobu.MixProject do
  use Mix.Project

  @version "0.1.0"
  @project_url "https://github.com/eugenweissbart/tobu_elixir"
  @docs_url "http://hexdocs.pm/tobu"

  def project do
    [
      app: :tobu,
      description:
        "A simple token bucket featuring multiple buckets with custom configurations, on-the-fly bucket creation and manual bucket depletion.",
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        coverage: :test,
        "coveralls.xml": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test,
        "coveralls.lcov": :test
      ],
      name: "Tobu",
      source_url: @project_url,
      homepage_url: @docs_url,
      docs: [
        main: "Tobu",
        source_url: @project_url,
        source_ref: "v#{@version}",
        extras: [],
        api_reference: false
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Tobu, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.13", only: :test}
    ]
  end
end
