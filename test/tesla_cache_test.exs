defmodule Tesla.Middleware.CacheXTest do
  use ExUnit.Case, async: false

  @expired_sleep 101

  setup do
    Application.ensure_all_started(:tesla_cache_cachex)
    {:ok, pid} = Agent.start_link(fn -> 0 end, name: :http_call_count)

    on_exit(fn ->
      Process.sleep(@expired_sleep)
      Process.exit(pid, :kill)
    end)
  end

  defmodule Client do
    use Tesla

    @ttl 100

    plug(Tesla.Middleware.Cache, ttl: @ttl)

    adapter(fn env ->
      increment_http_call_count()
      {status, headers, body} =
        case {env.url, env.query} do
          {"/200_OK", []} ->
            {200, %{'Content-Type' => 'text/plain'}, "OK"}

          {"/200_OK", [param: "a"]} ->
            {200, %{'Content-Type' => 'text/plain'}, "OK a"}

          {"/200_OK", [param: "b"]} ->
            {200, %{'Content-Type' => 'text/plain'}, "OK b"}

          {"/400_BAD_REQUEST", _} ->
            {400, %{'Content-Type' => 'text/plain'}, "Bad Request"}

          {"/500_INTERNAL_SERVER_ERROR", _} ->
            {500, %{'Content-Type' => 'text/plain'}, "Internal Server Error"}
        end

      {:ok, %{env | status: status, headers: headers, body: body}}
    end)

    def increment_http_call_count do
      Agent.update(:http_call_count, fn state -> state + 1 end)
    end

    def http_call_count do
      Agent.get(:http_call_count, fn state -> state end)
    end
  end

  describe "when response status code is 200" do
    setup do
      {:ok, res} = Client.get("/200_OK")
      [res: res]
    end

    test "should return the body as OK", context do
      assert context[:res].body == "OK"
    end

    test "result is OK", context do
      assert context[:res].body == "OK"
    end

    test "should do the real request in the first call" do
      assert Client.http_call_count() == 1
    end

    test "should not do the real request in the second call" do
      Client.get("/200_OK")
      assert Client.http_call_count() == 1
    end

    test "should do the real request again when cache expires" do
      Process.sleep(@expired_sleep)
      Client.get("/200_OK")
      assert Client.http_call_count() == 2
    end

    test "second request should have the same response value as the first one", context do
      {:ok, res2} = Client.get("/200_OK")
      assert context[:res] == res2
    end

    test "request with query params has different response" do
      {:ok, result} = Client.get("/200_OK", query: [param: "a"])
      assert result.body == "OK a"
    end

    test "request with query params should do the real request again" do
      Client.get("/200_OK", query: [param: "a"])
      assert Client.http_call_count() == 2
    end

    test "request with query params should not do the real request in the second call" do
      Client.get("/200_OK", query: [param: "a"])
      Client.get("/200_OK", query: [param: "a"])
      assert Client.http_call_count() == 2
    end

    test "request with different query params should do the request again" do
      Client.get("/200_OK", query: [param: "a"])
      Client.get("/200_OK", query: [param: "b"])
      assert Client.http_call_count() == 3
    end

    test "request with different query params should return the correct response" do
      Client.get("/200_OK", query: [param: "a"])
      {:ok, result} = Client.get("/200_OK", query: [param: "b"])
      assert result.body == "OK b"
    end
  end

  describe "when the response status code is 4xx" do
    test "should do the real request in the second call" do
      Client.get("/400_BAD_REQUEST")
      Client.get("/400_BAD_REQUEST")
      assert Client.http_call_count() == 2
    end
  end

  describe "when the response status code is 5xx" do
    test "should do the real request in the second call" do
      Client.get("/500_INTERNAL_SERVER_ERROR")
      Client.get("/500_INTERNAL_SERVER_ERROR")
      assert Client.http_call_count() == 2
    end
  end

  describe "when the HTTP Request method is not GET" do
    test "should not cache POST response" do
      Client.post("/200_OK", "data")
      Client.post("/200_OK", "data")
      assert Client.http_call_count() == 2
    end

    test "should not cache PUT response" do
      Client.put("/200_OK", "data")
      Client.put("/200_OK", "data")
      assert Client.http_call_count() == 2
    end

    test "should not cache DELETE response" do
      Client.delete("/200_OK")
      Client.delete("/200_OK")
      assert Client.http_call_count() == 2
    end
  end
end
