defmodule OffBroadway.Elasticsearch.SliceStrategy do
  @moduledoc """
  Implementation of `OffBroadway.Elasticsearch.Strategy` that's suitable
  for concurrent reading. Slices are determined by the `concurrency`
  option passed into the Broadway producer
  options.

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
              strategy: :slice, # <- Select the 'slice' strategy
              search: search() # <- Provide a search query
            ]
          },
          concurrency: 5 # <- Determines the max number of sliced search contexts to be created
        ],
        ...
      )
    end
  end
  ```

  See Elasticsearch docs: [Sliced Scroll](https://www.elastic.co/guide/en/elasticsearch/reference/8.13/paginate-search-results.html#slice-scroll)
  """

  @behaviour OffBroadway.Elasticsearch.Strategy

  @type broadway_state :: OffBroadway.Elasticsearch.broadway_state()
  @type document :: OffBroadway.Elasticsearch.document()

  @impl true
  @spec before_execute(state :: broadway_state(), demand :: non_neg_integer()) ::
          broadway_state()
  def before_execute(state, demand) do
    max_slices = get_in(state, [:broadway, :producer, :concurrency])
    index = get_in(state, [:broadway, :index])

    search =
      state[:search]
      |> add_size(demand)
      |> add_slice(index, max_slices)

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

  defp add_slice(search, index, max_slices) when is_map(search) do
    slice = %{id: index, max: max_slices}

    Map.put(search, :slice, slice)
  end
end
