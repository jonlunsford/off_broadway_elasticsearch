defmodule OffBroadway.Elasticsearch.Producer do
  @moduledoc """
  A GenStage producer that continuously fetches documents from Elasticsearch
  based on the configured strategy.

  Strategies are meant to provide flexibility based on your use case. The
  current strategies are:

  - `OffBroadway.Elasticsearch.SearchAfterStrategy`
  - `OffBroadway.Elasticsearch.SliceStrategy`
  - `OffBroadway.Elasticsearch.ScrollStrategy`

  See Elasticsearch docs: [Paginating Search Results](https://www.elastic.co/guide/en/elasticsearch/reference/8.13/paginate-search-results.html#paginate-search-results)
  """
  use GenStage
  require Logger

  alias OffBroadway.Elasticsearch.{SearchAfterStrategy, ScrollStrategy, SliceStrategy}

  @doc """
  Available strategies
  """
  @strategies %{
    search_after: SearchAfterStrategy,
    scroll: ScrollStrategy,
    slice: SliceStrategy
  }

  def start_link(opts) do
    GenStage.start_link(__MODULE__, :ok, opts)
  end

  def init(state \\ []) do
    strategy_mod = Map.get(@strategies, state[:strategy])
    state = Keyword.put(state, :strategy_mod, strategy_mod)

    {:producer, state}
  end

  def handle_demand(demand, state) when demand > 0 do
    mod = state[:strategy_mod]

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
