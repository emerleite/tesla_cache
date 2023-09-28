defmodule Tesla.Middleware.Support.CacheCounterCase do
  use ExUnit.CaseTemplate

  alias Tesla.Middleware.Support.TestClient

  using do
    quote do
      alias Tesla.Middleware.Support.TestClient

      import Tesla.Middleware.Support.CacheCounterCase
    end
  end

  setup do
    Application.ensure_all_started(:tesla_cache_cachex)
    {:ok, pid} = Agent.start_link(fn -> 0 end, name: :http_call_count)

    on_exit(fn ->
      TestClient.wait_for_cache_expiration()
      Process.exit(pid, :kill)
    end)
  end

  def increment_http_call_count do
    Agent.update(:http_call_count, fn state -> state + 1 end)
  end

  def http_call_count do
    Agent.get(:http_call_count, fn state -> state end)
  end
end
