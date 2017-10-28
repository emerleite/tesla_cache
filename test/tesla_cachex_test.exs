defmodule Tesla.Middleware.CacheXTest do
  use ExUnit.Case, async: false

  @expired_sleep 101

  setup do
    Application.ensure_all_started(:tesla_cache)
    {:ok, pid} = Agent.start_link(fn -> 0 end, name: :http_call_count)

    on_exit fn ->
      Process.sleep(@expired_sleep)
      Process.exit(pid, :kill)
    end
  end

  defmodule Client do
    use Tesla

    @ttl 100

    plug Tesla.Middleware.CacheX, ttl: @ttl

    adapter fn(env) ->
      {status, headers, body} = case env.url do
        "/200_OK" ->
          Agent.update(:http_call_count, fn state -> state + 1 end)
          {200, %{'Content-Type' => 'text/plain'}, "OK"}
        "/400_BAD_REQUEST" ->
          {400, %{'Content-Type' => 'text/plain'}, "Bad Request"}
        "/500_INTERNAL_SERVER_ERROR" ->
          {500, %{'Content-Type' => 'text/plain'}, "Internal Server Error"}
      end

      %{env | status: status, headers: headers, body: body}
    end
  end

  test "should do the real request in the first call" do
    Client.get("/200_OK")
    assert Agent.get(:http_call_count, fn state -> state end) == 1
  end

  test "should not do the real request in the second call" do
    Client.get("/200_OK")
    Client.get("/200_OK")
    assert Agent.get(:http_call_count, fn state -> state end) == 1
  end

  test "should do the real request again when cache expires" do
    Client.get("/200_OK")
    Process.sleep(@expired_sleep)
    Client.get("/200_OK")
    assert Agent.get(:http_call_count, fn state -> state end) == 2
  end
end
