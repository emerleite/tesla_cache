defmodule TeslaCache.Mixfile do
  use Mix.Project

  @description """
  TeslaCache is a middleware for Elixir Tesla HTTP Client
  """

  @project_url "https://github.com/emerleite/tesla_cache"

  def project do
    [
      app: :tesla_cache,
      version: "1.0.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      description: @description,
      source_url: @project_url,
      homepage_url: @project_url,
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      name: "TeslaCache",
      source_url: @project_url,
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TeslaCache.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cachex, "~> 2.1"},
      {:tesla, "~> 1.2"},
      {:excoveralls, "~> 0.7.2", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp package do
    [
      maintainers: ["Emerson Macedo"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/emerleite/tesla_cache"}
    ]
  end
end
