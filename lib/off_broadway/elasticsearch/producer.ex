defmodule OffBroadway.Elasticsearch.Producer do
  @moduledoc """
  A GenStage producer that continuously fetches documents from Elasticsearch
  based on the configured strategy.

  Strategies are meant to provide flexibility based on your use case. The
  current strategies are:

  - `OffBroadway.Elasticsearch.SearchAfterStrategy` - Docs: [Search After](https://www.elastic.co/guide/en/elasticsearch/reference/8.13/paginate-search-results.html#search-after)
  - `OffBroadway.Elasticsearch.ScrollStrategy`- Docs: [Scroll Search](https://www.elastic.co/guide/en/elasticsearch/reference/8.13/paginate-search-results.html#scroll-search-results)
  - `OffBroadway.Elasticsearch.SliceStrategy` - Docs: [Sliced Scroll](https://www.elastic.co/guide/en/elasticsearch/reference/8.13/paginate-search-results.html#slice-scroll)

  **The available options are:**

  - `host:` (`String.t()`) - Required. The host where Elasticsearch can be found.
  - `index:` (`String.t()`) - Required. The index to be ingested.
  - `search:` (`Map.t()`) - Required. The search payload to be sent to Elasticsearch.
  - `strategy:` (`Atom.t()`) - One of:
      - [`:search_after`](`OffBroadway.Elasticsearch.SearchAfterStrategy`)
      - [`:scroll`](`OffBroadway.Elasticsearch.ScrollStrategy`)
      - [`:slice`](`OffBroadway.Elasticsearch.SliceStrategy`)
  - `strategy_module:` (`Atom.t()`). A custom module that implemments
  `OffBroadway.Elasticsearch.Strategy` to be used if any of the built in
  strategies don't fit your use case.

  ## Example:

  ```
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
  """
  use GenStage
  require Logger

  alias OffBroadway.Elasticsearch.{SearchAfterStrategy, ScrollStrategy, SliceStrategy}

  @strategies %{
    search_after: SearchAfterStrategy,
    scroll: ScrollStrategy,
    slice: SliceStrategy
  }

  @doc """
  The available options are:

  - `host:` (`String.t()`) - Required. The host where Elasticsearch can be found.
  - `index:` (`String.t()`) - Required. The index to be ingested.
  - `search:` (`Map.t()`) - Required. The search payload to be sent to Elasticsearch.
  - `strategy:` (`Atom.t()`) - One of:
      - [`:search_after`](`OffBroadway.Elasticsearch.SearchAfterStrategy`)
      - [`:scroll`](`OffBroadway.Elasticsearch.ScrollStrategy`)
      - [`:slice`](`OffBroadway.Elasticsearch.SliceStrategy`)
  - `strategy_module:` (`Atom.t()`). A custom module that implements
  `OffBroadway.Elasticsearch.Strategy` to be used if any of the built in
  strategies don't fit your use case.
  """
  def start_link(opts) do
    GenStage.start_link(__MODULE__, :ok, opts)
  end

  def init(opts \\ []) do
    strategy_mod =
      case Keyword.get(opts, :strategy_module) do
        nil -> Map.get(@strategies, opts[:strategy])
        mod -> mod
      end

    opts = Keyword.put(opts, :strategy_module, strategy_mod)

    {:producer, opts}
  end

  def handle_demand(demand, state) when demand > 0 do
    mod = state[:strategy_module]

    state =
      if function_exported?(mod, :before_execute, 2) do
        mod.before_execute(state, demand)
      else
        state
      end

    {state, results} = mod.execute(state)

    state =
      if function_exported?(mod, :after_execute, 2) do
        mod.after_execute(state, results)
      else
        state
      end

    {:noreply, results, state}
  end

  def handle_demand(_demand, state) do
    Logger.info("No demand")
    {:noreply, [], state}
  end
end
