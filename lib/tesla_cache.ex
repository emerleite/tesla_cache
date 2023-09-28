defmodule Tesla.Middleware.Cache do
  @moduledoc false

  @behaviour Tesla.Middleware

  def call(env, next, opts) do
    ttl = Keyword.fetch!(opts, :ttl)
    cache_key_generator = Keyword.get(opts, :cache_key_generator, &default_cache_key/1)

    env
    |> get_from_cache(env.method, cache_key_generator)
    |> run(next)
    |> set_to_cache(ttl, cache_key_generator)
  end

  defp get_from_cache(env, :get, cache_key_generator) do
    {Cachex.get!(:tesla_cache_cachex, cache_key_generator.(env)), env}
  end

  defp get_from_cache(env, _method, _cache_key_generator), do: {nil, env}

  defp run({nil, request_env}, next) do
    {:ok, response_env} = Tesla.run(request_env, next)
    {:miss, request_env, response_env}
  end

  defp run({cached_env, request_env}, _next) do
    {:hit, request_env, cached_env}
  end

  defp set_to_cache(
         {:miss, request_env, %Tesla.Env{status: 200} = response_env},
         ttl,
         cache_key_generator
       ) do
    Cachex.put(:tesla_cache_cachex, cache_key_generator.(request_env), response_env, ttl: ttl)
    {:ok, response_env}
  end

  defp set_to_cache({:miss, _request_env, response_env}, _ttl, _cache_key_generator),
    do: {:ok, response_env}

  defp set_to_cache({:hit, _request_env, response_env}, _ttl, _cache_key_generator),
    do: {:ok, response_env}

  defp default_cache_key(%Tesla.Env{url: url, query: query}), do: Tesla.build_url(url, query)
end
