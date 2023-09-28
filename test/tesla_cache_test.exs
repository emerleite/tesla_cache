defmodule Tesla.Middleware.CacheTest do
  use Tesla.Middleware.Support.CacheCounterCase

  defp create_fixtures(_args) do
    %{client: TestClient.new()}
  end

  describe "when response status code is 200" do
    setup [:create_fixtures]

    test "should return the body as OK", %{client: client} do
      res = Tesla.get!(client, "/200_OK")

      assert res.body == "OK"
    end

    test "result is OK", %{client: client} do
      res = Tesla.get!(client, "/200_OK")

      assert res.body == "OK"
    end

    test "should do the real request in the first call", %{client: client} do
      Tesla.get!(client, "/200_OK")
      assert http_call_count() == 1
    end

    test "should not do the real request in the second call", %{client: client} do
      Tesla.get!(client, "/200_OK")
      Tesla.get!(client, "/200_OK")
      assert http_call_count() == 1
    end

    test "should do the real request again when cache expires", %{client: client} do
      Tesla.get!(client, "/200_OK")
      TestClient.wait_for_cache_expiration()
      Tesla.get!(client, "/200_OK")
      assert http_call_count() == 2
    end

    test "second request should have the same response value as the first one", %{
      client: client
    } do
      res = Tesla.get!(client, "/200_OK")
      res2 = Tesla.get!(client, "/200_OK")
      assert res == res2
    end

    test "request with query params has different response", %{client: client} do
      Tesla.get!(client, "/200_OK")
      result = Tesla.get!(client, "/200_OK", query: [param: "a"])
      assert result.body == "OK a"
    end

    test "request with query params should do the real request again", %{client: client} do
      Tesla.get!(client, "/200_OK")
      Tesla.get!(client, "/200_OK", query: [param: "a"])
      assert http_call_count() == 2
    end

    test "request with query params should not do the real request in the second call", %{
      client: client
    } do
      Tesla.get!(client, "/200_OK")
      Tesla.get!(client, "/200_OK", query: [param: "a"])
      Tesla.get!(client, "/200_OK", query: [param: "a"])
      assert http_call_count() == 2
    end

    test "request with different query params should do the request again", %{client: client} do
      Tesla.get!(client, "/200_OK")
      Tesla.get!(client, "/200_OK", query: [param: "a"])
      Tesla.get!(client, "/200_OK", query: [param: "b"])
      assert http_call_count() == 3
    end

    test "request with different query params should return the correct response", %{
      client: client
    } do
      Tesla.get!(client, "/200_OK")
      Tesla.get!(client, "/200_OK", query: [param: "a"])

      result = Tesla.get!(client, "/200_OK", query: [param: "b"])
      assert result.body == "OK b"
    end
  end

  describe "when the response status code is 4xx" do
    setup [:create_fixtures]

    test "should do the real request in the second call", %{client: client} do
      Tesla.get!(client, "/400_BAD_REQUEST")
      Tesla.get!(client, "/400_BAD_REQUEST")
      assert http_call_count() == 2
    end
  end

  describe "when the response status code is 5xx" do
    setup [:create_fixtures]

    test "should do the real request in the second call", %{client: client} do
      Tesla.get!(client, "/500_INTERNAL_SERVER_ERROR")
      Tesla.get!(client, "/500_INTERNAL_SERVER_ERROR")
      assert http_call_count() == 2
    end
  end

  describe "when the HTTP Request method is not GET" do
    setup [:create_fixtures]

    test "should not cache POST response", %{client: client} do
      Tesla.post!(client, "/200_OK", "data")
      Tesla.post!(client, "/200_OK", "data")
      assert http_call_count() == 2
    end

    test "should not cache PUT response", %{client: client} do
      Tesla.put!(client, "/200_OK", "data")
      Tesla.put!(client, "/200_OK", "data")
      assert http_call_count() == 2
    end

    test "should not cache DELETE response", %{client: client} do
      Tesla.delete!(client, "/200_OK")
      Tesla.delete!(client, "/200_OK")
      assert http_call_count() == 2
    end
  end
end
