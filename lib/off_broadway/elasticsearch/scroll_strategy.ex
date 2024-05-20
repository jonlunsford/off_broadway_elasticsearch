defmodule OffBroadway.Elasticsearch.ScrollStrategy do
  @moduledoc """
  Implementation of `OffBroadway.Elasticsearch.Strategy` that uses the "Scroll"
  feature of Elasticsearch. This strategy is best suited for a single producer,
  fetching less than `10,000` results per request. For concurrent searching, see
  `OffBroadway.Elasticsearch.SliceStrategy` and for searching with demand
  greater than `10,000` see `OffBroadway.Elasticsearch.SearchAfterStrategy`

  ## Example

  ```Elixir
  defmodule MyBroadway do
    use Broadway

    def start_link(_opts) do
      Broadway.start_link(__MODULE__,
        ...
        producer: [
          module: {
            OffBroadway.Elasticsearch.Producer,
            [
              host: "http://localhost:9200",
              index: "my-index",
              strategy: :scroll, # <- Select the 'scroll' strategy
              search: search() # <- Provide a search query
            ]
          },
          concurrency: 1 # <- A single process to manage 'scrolling'
        ],
        ...
      )
    end
  end
  ```

  See Elasticsearch docs: [Scroll Search](https://www.elastic.co/guide/en/elasticsearch/reference/8.13/paginate-search-results.html#scroll-search-results)
  """

  @behaviour OffBroadway.Elasticsearch.Strategy

  @typedoc """
  A keyword list of all Broadway options/state
  """
  @type broadway_state :: keyword()

  @typedoc """
  A Elasticsearch document represented as a Map. To allow maximum control, the
  entire document is returned, including metadata along with the `_source`.
  """
  @type document :: map()

  @impl true
  @spec before_execute(state :: broadway_state(), demand :: non_neg_integer()) ::
          broadway_state()
  def before_execute(state, demand) do
    search =
      state[:search]
      |> add_size(demand)

    state
    |> Keyword.put(:search, search)
  end

  @impl true
  @spec execute(state :: broadway_state()) :: {broadway_state(), list(document())}
  def execute(state) do
    case Keyword.fetch(state, :scroll_id) do
      :error -> initial_search(state)
      {:ok, _id} -> scroll_search(state)
    end
  end

  defp initial_search(state) do
    %Req.Response{body: %{"_scroll_id" => scroll_id, "hits" => %{"hits" => results}}} =
      Req.post!("#{state[:host]}/#{state[:index]}/_search",
        params: [scroll: "1m"],
        json: state[:search]
      )

    state = Keyword.put(state, :scroll_id, scroll_id)

    {state, results}
  end

  defp scroll_search(state) do
    %Req.Response{body: %{"_scroll_id" => scroll_id, "hits" => %{"hits" => results}}} =
      Req.post!("#{state[:host]}/_search/scroll",
        json: %{scroll: "1m", scroll_id: state[:scroll_id]}
      )

    state = Keyword.put(state, :scroll_id, scroll_id)

    {state, results}
  end

  defp add_size(search, nil) when is_map(search), do: search

  defp add_size(search, demand) when is_map(search) do
    Map.put(search, :size, demand)
  end
end
