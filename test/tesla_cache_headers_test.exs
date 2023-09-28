defmodule Tesla.Middleware.CacheHeadersTest do
  use Tesla.Middleware.Support.CacheCounterCase

  defp create_fixtures(_args) do
    client =
      TestClient.new(
        ttl: 100,
        cache_key_generator: fn %Tesla.Env{url: url, query: query, headers: headers} ->
          :crypto.hash(:md5, :erlang.term_to_binary({url, query, headers}))
        end
      )

    %{client: client, headers: [{"authorization", "Bearer test"}]}
  end

  describe "when response status code is 200" do
    setup [:create_fixtures]

    test "should return the body as OK", %{client: client, headers: headers} do
      res = Tesla.get!(client, "/200_OK", headers: headers)

      assert res.body == "OK"
    end

    test "result is OK", %{client: client, headers: headers} do
      res = Tesla.get!(client, "/200_OK", headers: headers)

      assert res.body == "OK"
    end

    test "should do the real request in the first call", %{client: client, headers: headers} do
      Tesla.get!(client, "/200_OK", headers: headers)
      assert http_call_count() == 1
    end

    test "should not do the real request in the second call", %{client: client, headers: headers} do
      Tesla.get!(client, "/200_OK", headers: headers)
      Tesla.get!(client, "/200_OK", headers: headers)
      assert http_call_count() == 1
    end

    test "should do the real request again when cache expires", %{
      client: client,
      headers: headers
    } do
      Tesla.get!(client, "/200_OK", headers: headers)
      TestClient.wait_for_cache_expiration()
      Tesla.get!(client, "/200_OK", headers: headers)
      assert http_call_count() == 2
    end

    test "second request should have the same response value as the first one", %{
      client: client,
      headers: headers
    } do
      res = Tesla.get!(client, "/200_OK", headers: headers)
      res2 = Tesla.get!(client, "/200_OK", headers: headers)
      assert res == res2
    end
  end

  describe "when response status code is 200 different query" do
    setup [:create_fixtures]

    test "request with query params has different response", %{client: client, headers: headers} do
      Tesla.get!(client, "/200_OK", headers: headers)
      result = Tesla.get!(client, "/200_OK", query: [param: "a"])
      assert result.body == "OK a"
    end

    test "request with query params should do the real request again", %{
      client: client,
      headers: headers
    } do
      Tesla.get!(client, "/200_OK", headers: headers)
      Tesla.get!(client, "/200_OK", query: [param: "a"], headers: headers)
      assert http_call_count() == 2
    end

    test "request with query params should not do the real request in the second call", %{
      client: client,
      headers: headers
    } do
      Tesla.get!(client, "/200_OK", headers: headers)
      Tesla.get!(client, "/200_OK", query: [param: "a"], headers: headers)
      Tesla.get!(client, "/200_OK", query: [param: "a"], headers: headers)
      assert http_call_count() == 2
    end

    test "request with different query params should do the request again", %{
      client: client,
      headers: headers
    } do
      Tesla.get!(client, "/200_OK", headers: headers)
      Tesla.get!(client, "/200_OK", query: [param: "a"], headers: headers)
      Tesla.get!(client, "/200_OK", query: [param: "b"], headers: headers)
      assert http_call_count() == 3
    end

    test "request with different query params should return the correct response", %{
      client: client,
      headers: headers
    } do
      Tesla.get!(client, "/200_OK", headers: headers)
      Tesla.get!(client, "/200_OK", query: [param: "a"], headers: headers)

      result = Tesla.get!(client, "/200_OK", query: [param: "b"], headers: headers)
      assert result.body == "OK b"
    end
  end

  describe "when response status code is 200 different headers" do
    setup [:create_fixtures]

    test "request with different headers should do the request again", %{
      client: client,
      headers: headers
    } do
      Tesla.get!(client, "/200_OK", headers: headers)
      Tesla.get!(client, "/200_OK", headers: [{"Accept", "application/json"}] ++ headers)
      Tesla.get!(client, "/200_OK", headers: [{"Accept", "text/html"}] ++ headers)
      assert http_call_count() == 3
    end

    test "request with different headers should not do the real request in the second call", %{
      client: client,
      headers: headers
    } do
      Tesla.get!(client, "/200_OK", headers: headers)
      Tesla.get!(client, "/200_OK", headers: [{"Accept", "application/json"}] ++ headers)
      Tesla.get!(client, "/200_OK", headers: [{"Accept", "application/json"}] ++ headers)
      assert http_call_count() == 2
    end
  end

  describe "when the response status code is 4xx" do
    setup [:create_fixtures]

    test "should do the real request in the second call", %{client: client, headers: headers} do
      Tesla.get!(client, "/400_BAD_REQUEST", headers: headers)
      Tesla.get!(client, "/400_BAD_REQUEST", headers: headers)
      assert http_call_count() == 2
    end
  end

  describe "when the response status code is 5xx" do
    setup [:create_fixtures]

    test "should do the real request in the second call", %{client: client, headers: headers} do
      Tesla.get!(client, "/500_INTERNAL_SERVER_ERROR", headers: headers)
      Tesla.get!(client, "/500_INTERNAL_SERVER_ERROR", headers: headers)
      assert http_call_count() == 2
    end
  end

  describe "when the HTTP Request method is not GET" do
    setup [:create_fixtures]

    test "should not cache POST response", %{client: client, headers: headers} do
      Tesla.post!(client, "/200_OK", "data", headers: headers)
      Tesla.post!(client, "/200_OK", "data", headers: headers)
      assert http_call_count() == 2
    end

    test "should not cache PUT response", %{client: client, headers: headers} do
      Tesla.put!(client, "/200_OK", "data", headers: headers)
      Tesla.put!(client, "/200_OK", "data", headers: headers)
      assert http_call_count() == 2
    end

    test "should not cache DELETE response", %{client: client, headers: headers} do
      Tesla.delete!(client, "/200_OK", headers: headers)
      Tesla.delete!(client, "/200_OK", headers: headers)
      assert http_call_count() == 2
    end
  end
end
