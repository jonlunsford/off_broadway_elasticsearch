defmodule OffBroadway.Elasticsearch do
  @moduledoc """
  Off Broadway Elasticsearch Producer.
  """

  @typedoc """
  A keyword list of all Broadway options / state
  """
  @type broadway_state :: keyword()

  @typedoc """
  A Elasticsearch document represented as a Map. To allow maximum control, the
  entire document is returned, including metadata along with the `_source`.
  """
  @type document :: map()
end
