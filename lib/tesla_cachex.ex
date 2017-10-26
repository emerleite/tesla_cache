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
    Map.update!(env, :body, Cachex.get!(:tesla_cache, env.url))
    {env.body, env}
  end

  defp run({nil, env}, next) do
    Tesla.run(env, next)    
  end
  defp run({_, env}, next), do: :hit

  defp set_to_cache(:hit, ttl), do: nil
  defp set_to_cache(env, ttl) do
    Cachex.set(:tesla_cache, env.url, env.body, ttl: ttl)
  end
end
