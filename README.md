# TeslaCache

[![Build Status](https://travis-ci.org/emerleite/tesla_cache.svg?branch=master)](https://travis-ci.org/emerleite/tesla_cache)
[![Coverage Status](https://coveralls.io/repos/github/emerleite/tesla_cache/badge.svg?branch=master)](https://coveralls.io/github/emerleite/tesla_cache?branch=master)
[![codecov](https://codecov.io/gh/emerleite/tesla_cache/branch/master/graph/badge.svg)](https://codecov.io/gh/emerleite/tesla_cache)

TeslaCache is a Basic Cache Middleware for Tesla.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tesla_cache` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tesla_cache, "~> 0.1.0"}
  ]
end
```

## Usage:

```elixir
defmodule GoogleClient do
  use Tesla

  plug Tesla.Middleware.Cache, ttl: :timer.seconds(2)
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/tesla_cache](https://hexdocs.pm/tesla_cache).

