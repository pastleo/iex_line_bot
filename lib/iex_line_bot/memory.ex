defmodule IexLineBot.Memory do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key, []))
  end

  def set(key, bindings) do
    Agent.update(__MODULE__, &Map.put(&1, key, bindings))
  end
end
