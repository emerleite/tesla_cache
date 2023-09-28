defmodule TeslaCache.Mixfile do
  use Mix.Project

  @description "TeslaCache is a middleware for Elixir Tesla HTTP Client"
  @project_url "https://github.com/emerleite/tesla_cache"

  def project do
    [
      app: :tesla_cache,
      version: "1.1.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: @description,
      source_url: @project_url,
      homepage_url: @project_url,
      package: package(),
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      name: "TeslaCache",
      docs: [
        main: "readme",
        api_reference: false,
        extras: ["README.md"],
        extra_section: []
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {TeslaCache.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_other), do: ["lib"]

  defp deps do
    [
      {:cachex, "~> 3.6"},
      {:tesla, "~> 1.7"},
      {:excoveralls, "~> 0.17.1", only: :test},
      {:ex_doc, "~> 0.30.0", runtime: false, only: [:dev]}
    ]
  end

  defp package do
    [
      maintainers: ["Emerson Macedo"],
      licenses: ["MIT"],
      links: %{"GitHub" => @project_url}
    ]
  end
end
