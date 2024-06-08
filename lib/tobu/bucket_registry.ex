defmodule Tobu.BucketRegistry do
  @moduledoc false
  use GenServer

  @type bucket :: %{
          capacity: integer(),
          available: integer(),
          refresh_interval: integer(),
          refresh_amount: integer()
        }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl true
  def init(opts) do
    capacity = Keyword.get(opts, :capacity)
    refresh_interval = Keyword.get(opts, :refresh_interval)
    refresh_amount = Keyword.get(opts, :refresh_amount)

    {:ok,
     %{
       capacity: capacity,
       refresh_interval: refresh_interval,
       refresh_amount: refresh_amount,
       timers: %{},
       buckets: %{}
     }}
  end

  @impl true
  def handle_cast({:new, bucket, opts}, state) do
    {
      :noreply,
      create_bucket(state, bucket, opts)
    }
  end

  def handle_cast({:manual_deplete, bucket, refresh_after, refresh_amount}, state) do
    case get_in(state, [:buckets, bucket]) do
      nil ->
        {:reply, {:error, :bucket_not_found}, state}

      data ->
        :timer.send_after(
          refresh_after,
          __MODULE__,
          {:manual_refresh, bucket, refresh_amount || data[:refresh_amount]}
        )

        state
        |> tap(fn %{timers: %{^bucket => timer}} ->
          :timer.cancel(timer)
        end)
        |> put_in([:timers, bucket], nil)
        |> put_in([:buckets, bucket], %{data | available: 0})
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_info({:refresh, bucket, refresh_amount, capacity}, state),
    do:
      {:noreply,
       update_in(state, [:buckets, bucket, :available], &min(capacity, &1 + refresh_amount))}

  def handle_info({:manual_refresh, bucket, refresh_amount}, state) do
    case get_in(state, [:buckets, bucket]) do
      nil ->
        {:noreply, state}

      data ->
        state
        |> put_in([:buckets, bucket], %{
          data
          | available: min(data[:capacity], data[:available] + refresh_amount)
        })
        |> then(fn state ->
          {:ok, tref} =
            :timer.send_interval(
              data[:refresh_interval],
              __MODULE__,
              {:refresh, bucket, data[:refresh_amount], data[:capacity]}
            )

          put_in(state, [:timers, bucket], tref)
        end)
        |> then(&{:noreply, &1})
    end
  end

  @impl true
  def handle_call({:get, bucket, amount}, _from, state) do
    case get_in(state, [:buckets, bucket]) do
      nil ->
        {:reply, {:error, :bucket_not_found}, state}

      %{available: available} = data when available >= amount ->
        data
        |> put_in([:available], available - amount)
        |> then(&{:reply, {:ok, &1}, %{state | buckets: Map.put(state[:buckets], bucket, &1)}})

      data ->
        {:reply, {:error, data}, state}
    end
  end

  def handle_call({:get_or_create, bucket, amount, opts}, from, state) do
    case get_in(state, [:buckets, bucket]) do
      nil ->
        state
        |> create_bucket(bucket, opts)
        |> then(&handle_call({:get, bucket, amount}, from, &1))

      _data ->
        handle_call({:get, bucket, amount}, from, state)
    end
  end

  def handle_call({:inspect, bucket}, _from, state) do
    case get_in(state, [:buckets, bucket]) do
      nil ->
        {:reply, {:error, :bucket_not_found}, state}

      data ->
        {:reply, {:ok, data}, state}
    end
  end

  defp create_bucket(state, bucket, opts) do
    capacity = get_argument(:capacity, opts, state)
    refresh_interval = get_argument(:refresh_interval, opts, state)
    refresh_amount = get_argument(:refresh_amount, opts, state)

    {:ok, tref} =
      :timer.send_interval(
        refresh_interval,
        __MODULE__,
        {:refresh, bucket, refresh_amount, capacity}
      )

    state
    |> put_in([:timers, bucket], tref)
    |> put_in([:buckets, bucket], %{
      available: capacity,
      capacity: capacity,
      refresh_interval: refresh_interval,
      refresh_amount: refresh_amount
    })
  end

  defp get_argument(key, opts, state),
    do: Keyword.get(opts, key) || Map.get(state, key) || argument_error(key)

  defp argument_error(key),
    do:
      raise(ArgumentError,
        message: "#{key} is not specified. Specify it either in config or as a keyword argument."
      )
end
