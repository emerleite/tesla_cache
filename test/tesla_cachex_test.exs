defmodule Tesla.Middleware.CacheXTest do
  use ExUnit.Case, async: false

  defmodule Client do
    use Tesla

    plug Tesla.Middleware.CacheX, ttl: 2_000

    adapter fn(env) ->
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
end
