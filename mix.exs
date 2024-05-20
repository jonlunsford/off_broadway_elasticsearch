defmodule OffBroadway.Elasticsearch.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "An Elasticsearch connector for Broadway"
  @repo_url "https://github.com/jonlunsford/off_broadway_elasticsearch"

  def project do
    [
      app: :off_broadway_elasticsearch,
      version: @version,
      elixir: "~> 1.15",
      name: "OffBroadway.Elasticsearch",
      description: @description,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:broadway, "~> 1.0.7"},
      {:ex_doc, ">= 0.32.2", only: [:dev, :docs], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:req, "~> 0.4.0"}
    ]
  end

  defp docs do
    [
      main: "README.md",
      nest_modules_by_prefix: [OffBroadway.Elasticsearch],
      groups_for_modules: [
        "Search Strategies": [
          OffBroadway.Elasticsearch.SearchAfterStrategy,
          OffBroadway.Elasticsearch.SliceStrategy,
          OffBroadway.Elasticsearch.ScrollStrategy
        ],
        Behaviors: [OffBroadway.Elasticsearch.Strategy]
      ],
      source_url: @repo_url,
      source_ref: "#{@version}"
    ]
  end

  defp package do
    [
      maintainers: ["Jon Lunsford"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @repo_url,
        "Documentation" => "https://hexdocs.pm/off_broadway_elasticsearch",
        "Changelog" => @repo_url <> "/blob/main/CHANGELOG.md",
        "Source" => @repo_url <> ".git"
      }
    ]
  end
end
