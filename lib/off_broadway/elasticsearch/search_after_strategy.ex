defmodule OffBroadway.Elasticsearch.SearchAfterStrategy do
  @moduledoc """
  Implementation of `OffBroadway.Elasticsearch.Strategy` that's able to fetch
  more than `10,000` results per request by using Elasticsearch's `search_after`
  feature. This strategy is best suited for a single producer and the
  search query must be sorted in some way. For concurrent searching, see
  `OffBroadway.Elasticsearch.SliceStrategy`

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
              strategy: :search_after, # <- Select the 'search_after' strategy
              search: search() # <- Provide a search query
            ]
          },
          concurrency: 1 # <- Best
        ],
        ...
      )
    end

    def search do
      %{
        query: %{
          match_all: %{}
        },
        sort: %{ # <- Must be present so Elasticsearch returns the `search_after` keys/values
          created_at: "asc",
          _id: "asc"
        }
      }
    end
  end
  ```
  See Elasticsearch docs: [Search After](https://www.elastic.co/guide/en/elasticsearch/reference/8.13/paginate-search-results.html#search-after)
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
      |> add_search_after(state[:search_after])
      |> add_size(demand)

    state
    |> Keyword.put(:search, search)
  end

  @impl true
  @spec execute(state :: broadway_state()) :: {broadway_state(), list(document())}
  def execute(state) do
    %Req.Response{body: %{"hits" => %{"hits" => results}}} =
      Req.get!("#{state[:host]}/#{state[:index]}/_search", json: state[:search])

    {state, results}
  end

  @impl true
  @spec after_execute(state :: broadway_state(), results :: list(document())) ::
          broadway_state()
  def after_execute(state, results) do
    state
    |> Keyword.put(:search_after, hd(results)["sort"])
  end

  defp add_search_after(search, []) when is_map(search), do: search
  defp add_search_after(search, nil) when is_map(search), do: search

  defp add_search_after(search, search_after) when is_map(search) do
    Map.put(search, :search_after, search_after)
  end

  defp add_size(search, nil) when is_map(search), do: search

  defp add_size(search, demand) when is_map(search) do
    Map.put(search, :size, demand)
  end
end
