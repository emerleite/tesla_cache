 defmodule Tesla.Middleware.CacheX do
  @behaviour Tesla.Middleware

  @moduledoc """
  Cache the response for X milliseconds.

  ### Example
  ```
  defmodule MyClient do
    use Tesla

    plug Tesla.Middleware.CacheX, ttl: :timer.minutes(10)
  end
  """

  def call(env, next, [ttl: ttl]) do
    env
    |> get_from_cache
    |> run(next)
    |> set_to_cache(ttl)
  end

  defp get_from_cache(env) do
    env = Map.update!(env, :body, fn _ -> Cachex.get!(:tesla_cache, env.url) end)
    {env.body, env}
  end

  defp run({nil, env}, next) do
    {:miss, Tesla.run(env, next)}
  end
  defp run({_, env}, _next) do
    {:hit, env}
  end

  defp set_to_cache({:miss, %Tesla.Env{status: status, body: body, url: url}}, ttl) when status == 200 do
    Cachex.set(:tesla_cache, url, body, ttl: ttl)
  end
  defp set_to_cache({:miss, env}, _ttl), do: env
  defp set_to_cache({:hit, env}, _ttl), do: env
end
