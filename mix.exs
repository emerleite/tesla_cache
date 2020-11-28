defmodule TeslaCache.Mixfile do
  use Mix.Project

  @description "TeslaCache is a middleware for Elixir Tesla HTTP Client"
  @project_url "https://github.com/emerleite/tesla_cache"

  def project do
    [
      app: :tesla_cache,
      version: "1.1.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      description: @description,
      source_url: @project_url,
      homepage_url: @project_url,
      package: package(),
      deps: deps(),
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

  defp deps do
    [
      {:cachex, "~> 2.1"},
      {:tesla, "~> 1.2"},

      {:excoveralls, "~> 0.7.2", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
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
