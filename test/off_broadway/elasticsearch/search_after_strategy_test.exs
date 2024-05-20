defmodule OffBroadway.Elasticsearch.SearchAfterStrategyTest do
  use ExUnit.Case

  alias OffBroadway.Elasticsearch.SearchAfterStrategy

  describe "before_execute/2" do
    test "it doesn't add search_after if it's empty" do
      state = SearchAfterStrategy.before_execute([search: %{}], 5)
      search = state[:search]

      refute Map.has_key?(search, :search_after)
    end

    test "it adds search_after if it's present" do
      state =
        SearchAfterStrategy.before_execute(
          [search: %{}, search_after: [1, 2]],
          5
        )

      search = state[:search]

      assert %{search_after: [1, 2]} = search
    end

    test "it doesn't add the 'size' key if demand is not present" do
      state = SearchAfterStrategy.before_execute([search: %{}], nil)
      search = state[:search]

      refute Map.has_key?(search, :size)
    end

    test "it adds size if it is present" do
      state = SearchAfterStrategy.before_execute([search: %{}], 5)
      search = state[:search]

      assert %{size: 5} = search
    end
  end
end
