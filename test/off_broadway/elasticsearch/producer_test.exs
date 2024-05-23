defmodule OffBroadway.Elasticsearch.ProducerTest do
  use ExUnit.Case

  alias OffBroadway.Elasticsearch.{
    SearchAfterStrategy,
    ScrollStrategy,
    SliceStrategy,
    Producer,
    TestMod
  }

  describe "init/1" do
    test "it selects the correct module for the :search_after strategy" do
      {:producer, opts} = Producer.init(strategy: :search_after)

      assert SearchAfterStrategy = opts[:strategy_module]
    end

    test "it selects the correct module for the :scroll strategy" do
      {:producer, opts} = Producer.init(strategy: :scroll)

      assert ScrollStrategy = opts[:strategy_module]
    end

    test "it selects the correct module for the :slice strategy" do
      {:producer, opts} = Producer.init(strategy: :slice)

      assert SliceStrategy = opts[:strategy_module]
    end

    test "it selects a custom module if provided" do
      {:producer, opts} = Producer.init(strategy_module: TestMod)

      assert TestMod = opts[:strategy_module]
    end
  end

  describe "execute/2" do
    test "it calls before_execute on opts[:strategy_module]" do
      state = [strategy_module: TestMod]

      {:noreply, _results, updated_state} = Producer.handle_demand(5, state)

      assert Keyword.get(updated_state, :before_execute) == true
    end

    test "it calls execute on opts[:strategy_module]" do
      state = [strategy_module: TestMod]

      {:noreply, _results, updated_state} = Producer.handle_demand(5, state)

      assert Keyword.get(updated_state, :execute) == true
    end

    test "it calls after_execute on opts[:strategy_module]" do
      state = [strategy_module: TestMod]

      {:noreply, _results, updated_state} = Producer.handle_demand(5, state)

      assert Keyword.get(updated_state, :after_execute) == true
    end
  end
end

defmodule OffBroadway.Elasticsearch.TestMod do
  @behaviour OffBroadway.Elasticsearch.Strategy

  def before_execute(state, _demand) do
    state
    |> Keyword.put(:before_execute, true)
  end

  def execute(state) do
    state = Keyword.put(state, :execute, true)

    {state, []}
  end

  def after_execute(state, _results) do
    state
    |> Keyword.put(:after_execute, true)
  end
end
