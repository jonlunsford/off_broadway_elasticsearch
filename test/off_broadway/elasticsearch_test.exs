defmodule OffBroadway.ElasticsearchTest do
  use ExUnit.Case
  doctest OffBroadway.Elasticsearch

  test "greets the world" do
    assert OffBroadway.Elasticsearch.hello() == :world
  end
end
