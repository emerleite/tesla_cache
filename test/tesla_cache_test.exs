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
        case env.url do
          "/200_OK" ->
            {200, %{'Content-Type' => 'text/plain'}, "OK"}

          "/400_BAD_REQUEST" ->
            {400, %{'Content-Type' => 'text/plain'}, "Bad Request"}

          "/500_INTERNAL_SERVER_ERROR" ->
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
      [res: Client.get("/200_OK")]
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
      assert context[:res] == Client.get("/200_OK")
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
