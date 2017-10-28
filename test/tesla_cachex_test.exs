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
      Agent.update(:http_call_count, fn state -> state + 1 end)
      {status, headers, body} = case env.url do
        "/200_OK" ->
          {200, %{'Content-Type' => 'text/plain'}, "OK"}
        "/400_BAD_REQUEST" ->
          {400, %{'Content-Type' => 'text/plain'}, "Bad Request"}
        "/500_INTERNAL_SERVER_ERROR" ->
          {500, %{'Content-Type' => 'text/plain'}, "Internal Server Error"}
      end

      %{env | status: status, headers: headers, body: body}
    end
  end

  describe "when response status code is 200" do
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

  describe "when the response status code is 4xx" do
    test "should do the real request in the second call" do
      Client.get("/400_BAD_REQUEST")
      Client.get("/400_BAD_REQUEST")
      assert Agent.get(:http_call_count, fn state -> state end) == 2
    end
  end

  describe "when the response status code is 5xx" do
    test "should do the real request in the second call" do
      Client.get("/500_INTERNAL_SERVER_ERROR")
      Client.get("/500_INTERNAL_SERVER_ERROR")
      assert Agent.get(:http_call_count, fn state -> state end) == 2
    end
  end

  describe "when the HTTP Request method is not GET" do
    test "should not cache POST response" do
      Client.post("/200_OK", "data")
      Client.post("/200_OK", "data")
      assert Agent.get(:http_call_count, fn state -> state end) == 2
    end

    test "should not cache PUT response" do
      Client.put("/200_OK", "data")
      Client.put("/200_OK", "data")
      assert Agent.get(:http_call_count, fn state -> state end) == 2
    end

    test "should not cache DELETE response" do
      Client.delete("/200_OK")
      Client.delete("/200_OK")
      assert Agent.get(:http_call_count, fn state -> state end) == 2
    end
  end
end
