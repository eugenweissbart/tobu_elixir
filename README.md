## Tobu

[![tests](https://github.com/eugenweissbart/tobu_elixir/workflows/tests/badge.svg)](https://github.com/eugenweissbart/tobu_elixir/actions?query=workflow:"tests")
[![GitHub tag](https://img.shields.io/github/tag/eugenweissbart/tobu_elixir?include_prereleases=&sort=semver&color=9d2134)](https://github.com/eugenweissbart/tobu_elixir/releases/)
[![License](https://img.shields.io/badge/License-MIT-9d2134)](#license)
[![Hex version badge](https://img.shields.io/hexpm/v/tobu.svg)](https://hex.pm/packages/tobu)
[![Hexdocs badge](https://img.shields.io/badge/hex-docs-lightblue)](https://hexdocs.pm/tobu)

A simple token bucket featuring multiple buckets with custom configurations, on-the-fly bucket creation and manual bucket depletion.

## Installation

Add `tobu_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tobu_elixir, "~> 0.1.0"}
  ]
end
```

## Configuration

The configuration is optional, if you want to specify parameters for each bucket individually. To set default parameters, put them in your config file as follows:  

```elixir
config :tobu,
  capacity: 100,
  refresh_interval: 10_000,
  refresh_amount: 10
```

This sets the default capacity to 100, increased by 10 each 10 seconds. The buckets start with full capacity.

## Usage

To create a bucket, issue `Tobu.new_bucket/2`. Bucket names can be either strings or atoms. You can override the defaults specified in config by providing a keyword list as a second argument. If the defaults were not specified in config, you have to provide them here.

To get an amount of tokens from a bucket, issue `Tobu.get/2`. It will either return an ok-tuple with current bucket state, or an error-tuple if bucket not exists or not enough tokens are available.

If you want to automatically create a non-existing bucket upon token acquisition, use `Tobu.get_or_create/3`. The results will be the same, except for when the bucket does not exist, it will be created then a requested amount will be acquired from it.

In some cases, you may want to override bucket token availability (e.g. when the remote system unexpectedly reported hitting rate limits). For this, you may use `Tobu.manual_deplete/3`. This command results in following:

- Setting available token count in a bucket to 0
- Cancelling the existing refresh interval
- Scheduling the bucket to refresh after the time specified in `refresh_after`

The `refresh_amount` argument is optional, and if not specified, will default to bucket's refresh amount (either specified upon bucket creation or the default one).  

After the manual refresh has been issued, the standard refresh interval will be re-established.

To inspect current bucket state, use `Tobu.inspect/1`. It will return an ok-tuple or an error-tuple if the bucket exists or not, accordingly.