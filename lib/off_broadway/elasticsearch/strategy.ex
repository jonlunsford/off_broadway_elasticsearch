defmodule OffBroadway.Elasticsearch.Strategy do
  @moduledoc """
  Elasticseach supports many strategies for efficiently searching over large
  amounts of data, by adopting a strategy pattern, different strategies can be
  created and configured depending on the use case.

  To learn more about other strategies see Elasticsearch docs: [Paginating Search Results](https://www.elastic.co/guide/en/elasticsearch/reference/8.13/paginate-search-results.html#paginate-search-results)
  """

  alias OffBroadway.Elasticsearch

  @typedoc """
  A keyword list of all Broadway options/state
  """
  @type broadway_state :: Elasticsearch.broadway_state()

  @typedoc """
  A Elasticsearch document represented as a Map. To allow maximum control, the
  entire document is returned, including metadata along with the `_source`.
  """
  @type document :: Elasticsearch.document()

  @doc """
  Optionally called _before_ the strategy is executed. It's often
  necessary to modify search parameters or other state of the producer before
  requests are sent to Elasticsearch.
  """
  @callback before_execute(state :: broadway_state(), demand :: non_neg_integer()) ::
              broadway_state()

  @doc """
  Called immediately after `before_execute` with the modified `broadway_state()`.
  This function should make the request to Elasticsearch to satisfy demand.
  """
  @callback execute(state :: broadway_state()) ::
              {broadway_state(), list(document())}

  @doc """
  Optionally called after `execute` with the current `broadway_state()` and the
  results of `execute`, a list of `document()`. Depending on the search strategy
  used, Elasticsearch can return _new_ state that needs to be used in the next
  request. For example, the `ScrollSearch` strategy must pass the current
  `scroll_id` to the next request to return the next batch of results.
  """
  @callback after_execute(
              state :: broadway_state(),
              results ::
                list(document())
            ) :: broadway_state()

  @optional_callbacks after_execute: 2, before_execute: 2
end
