defmodule Tesla.Middleware.Support.TestClient do
  alias Tesla.Middleware.Support.CacheCounterCase

  @ttl 100
  @expired_sleep 101

  def new(opts \\ [ttl: @ttl]) do
    middleware = [
      {Tesla.Middleware.Cache, opts}
    ]

    Tesla.client(middleware, &custom_adapter/1)
  end

  def wait_for_cache_expiration, do: Process.sleep(@expired_sleep)

  defp custom_adapter(env) do
    CacheCounterCase.increment_http_call_count()

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
  end
end
