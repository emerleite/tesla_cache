defmodule Tesla.Middleware.Cache do
  @behaviour Tesla.Middleware

  @moduledoc """
  Cache the response for X milliseconds.

  ### Example
  ```
  defmodule MyClient do
    use Tesla

    plug Tesla.Middleware.Cache, ttl: :timer.minutes(10)
  end
  """

  def call(env, next, ttl: ttl) do
    env
    |> get_from_cache(env.method)
    |> run(next)
    |> set_to_cache(ttl)
  end

  defp get_from_cache(env, :get) do
    {Cachex.get!(:tesla_cache_cachex, env.url), env}
  end

  defp get_from_cache(env, _), do: {nil, env}

  defp run({nil, env}, next) do
    {:ok, env} = Tesla.run(env, next)
    {:miss, env}
  end

  defp run({cached_env, _env}, _next) do
    {:hit, cached_env}
  end

  defp set_to_cache({:miss, %Tesla.Env{status: status} = env}, ttl) when status == 200 do
    Cachex.set(:tesla_cache_cachex, env.url, env, ttl: ttl)
    env
  end

  defp set_to_cache({:miss, env}, _ttl), do: env
  defp set_to_cache({:hit, env}, _ttl), do: env
end
