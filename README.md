# OffBroadway.Elasticsearch

![Hex.pm Version](https://img.shields.io/hexpm/v/off_broadway_elasticsearch)

A flexible and extensible Elasticsearch producer for [Broadway](https://github.com/plataformatec/broadway) to process large amounts of data from your Elasticsearch cluster.

Full documentation can be found at https://hexdocs.pm/off_broadway_elasticsearch

This project provides:

### Producer

`OffBroadway.Elasticsearch.Producer`

A GenStage producer that continuously fetches documents from Elasticsearch based on the configured strategy.

### Search Strategies

Strategies are meant to provide flexibility based on your use case. The current strategies are:

- `OffBroadway.Elasticsearch.SearchAfterStrategy` - Docs: [Search After](https://www.elastic.co/guide/en/elasticsearch/reference/8.13/paginate-search-results.html#search-after)
- `OffBroadway.Elasticsearch.ScrollStrategy`- Docs: [Scroll Search](https://www.elastic.co/guide/en/elasticsearch/reference/8.13/paginate-search-results.html#scroll-search-results)
- `OffBroadway.Elasticsearch.SliceStrategy` - Docs: [Sliced Scroll](https://www.elastic.co/guide/en/elasticsearch/reference/8.13/paginate-search-results.html#slice-scroll)

If any of the built strategies don't fit your use case you can provide your own
implementation of `OffBroadway.Elasticsearch.Strategy` and pass it to the
producer via the `strategy_module:` option.

## Installation

Add `off_broadway_elasticsearch` to the list of dependences in your `mix.exs` file:

```elixir
def deps do
  [
    {:off_broadway_elasticsearch, "~> 0.1.0"}
  ]
end
```

## Usage

**The available options are:**

- `host:` (`String.t()`) - Required. The host where Elasticsearch can be found.
- `index:` (`String.t()`) - Required. The index to be ingested.
- `search:` (`Map.t()`) - Required. The search payload to be sent to Elasticsearch.
- `strategy:` (`Atom.t()`) - One of:
  - [`:search_after`](https://github.com/jonlunsford/off_broadway_elasticsearch/blob/main/lib/off_broadway/elasticsearch/search_after_strategy.ex)
  - [`:scroll`](https://github.com/jonlunsford/off_broadway_elasticsearch/blob/main/lib/off_broadway/elasticsearch/scroll_strategy.ex)
  - [`:slice`](https://github.com/jonlunsford/off_broadway_elasticsearch/blob/main/lib/off_broadway/elasticsearch/slice_strategy.ex)
- `strategy_module:` (`Atom.t()`). A custom module that implements
  `OffBroadway.Elasticsearch.Strategy` to be used if any of the built in
  strategies don't fit your use case.

### Example:

```Elixir
defmodule MyBroadway do
  use Broadway

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          OffBroadway.Elasticsearch.Producer,
          [
            # The options listed above.
            host: "http://localhost:9200",
            index: "my-index",
            strategy: :slice,
            # If `strategy_module` is provided, it will take precedence over
            # `strategy`, that can be omitted when providing this option.
            strategy_module: MySearchStrategy
            search: search() # Extracted to a private function below.
          ]
        },
        transformer: {__MODULE__, :transform, []},
        concurrency: 10
      ],
      processors: [
        default: [concurrency: 5]
      ]
    )
  end

  defp search do
    %{
      query: %{
        match_all: %{}
      },
      sort: %{
        created_at: "asc",
        _id: "asc"
      }
    }
  end
end
```
