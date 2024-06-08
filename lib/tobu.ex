defmodule Tobu do
  @moduledoc File.read!("README.md")

  use Application

  alias Tobu.BucketRegistry

  @type opts ::
          {:capacity, integer()} | {:refresh_interval, integer()} | {:refresh_amount, integer()}

  @type bucket :: %{
          capacity: integer(),
          available: integer(),
          refresh_interval: integer(),
          refresh_amount: integer()
        }

  @impl true
  @doc false
  def start(_type, _args) do
    children =
      if Application.get_env(:tobu, :environment) == :test,
        do: [],
        else: [
          {Tobu.BucketRegistry, Application.get_all_env(:tobu)}
        ]

    opts = [strategy: :one_for_one, name: Tobu.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Creates a new bucket.
  If the options are not provided, the default values are used.
  If no defaults are provided, the options are required.

  ## Parameters

  - name: The name of the bucket
  - opts: The options
    - capacity: The capacity of the bucket
    - refresh_interval: The refresh interval of the bucket in milliseconds
    - refresh_amount: The amount to refresh the bucket

  ## Examples

      iex> Tobu.new_bucket("test")
      :ok

      iex> Tobu.new_bucket("test", capacity: 10, refresh_interval: 1000, refresh_amount: 1)
      :ok
  """
  @spec new_bucket(name :: binary() | atom(), opts :: [opts]) :: :ok
  def new_bucket(name, opts \\ []) do
    GenServer.cast(BucketRegistry, {:new, name, opts})
  end

  @doc """
  Gets a token from a bucket.
  On success, returns an ok-tuple including current bucket state.
  If the bucket does not exist, it returns an error.
  If the amount is greater than the capacity, it returns an error.

  ## Parameters

  - bucket: The name of the bucket
  - amount: The amount of tokens to get

  ## Examples

      iex> Tobu.get("test", 1)
      {:ok, %{available: 9, capacity: 10, refresh_amount: 1, refresh_interval: 1000}}

      iex> Tobu.get("foo", 1)
      {:error, :bucket_not_found}

      iex> Tobu.get("test", 11)
      {:error, %{available: 10, capacity: 10, refresh_amount: 1, refresh_interval: 1000}}
  """
  @spec get(bucket :: binary(), amount :: integer()) ::
          {:ok, bucket()}
          | {:error, :bucket_not_found}
          | {:error, bucket()}
  def get(bucket, amount) do
    GenServer.call(BucketRegistry, {:get, bucket, amount})
  end

  @doc """
  Gets a token from a bucket or creates a new bucket if it does not exist.
  On success, returns an ok-tuple including current bucket state.
  If the amount is greater than the capacity, it returns an error.

  ## Parameters

  - bucket: The name of the bucket
  - amount: The amount of tokens to get
  - opts: The options
    - capacity: The capacity of the bucket
    - refresh_interval: The refresh interval of the bucket in milliseconds
    - refresh_amount: The amount to refresh the bucket

  ## Examples

      iex> Tobu.get_or_create("test", 1)
      {:ok, %{available: 9, capacity: 10, refresh_amount: 1, refresh_interval: 1000}}

      iex> Tobu.get_or_create("foo", 1)
      {:ok, %{available: 9, capacity: 10, refresh_amount: 1, refresh_interval: 1000}}

      iex> Tobu.get_or_create("test", 11)
      {:error, %{available: 10, capacity: 10, refresh_amount: 1, refresh_interval: 1000}}
  """
  @spec get_or_create(bucket :: binary(), amount :: integer(), opts :: [opts]) ::
          {:ok, bucket()}
          | {:error, bucket()}
  def get_or_create(bucket, amount, opts \\ []) do
    GenServer.call(BucketRegistry, {:get_or_create, bucket, amount, opts})
  end

  @doc """
  Sets available tokens in a bucket to 0 and specifies next refresh interval and optionally next refresh amount.
  If the bucket does not exist, it returns an error.

  ## Parameters

  - bucket: The name of the bucket
  - refresh_amount: The amount to refresh the bucket

  ## Examples

      iex> Tobu.manual_refresh("test", 10_000)
      :ok

      iex> Tobu.manual_refresh("test", 10_000, 5)
      :ok

      iex> Tobu.manual_refresh("foo", 10_000)
      {:error, :bucket_not_found}
  """
  @spec manual_deplete(
          bucket :: binary(),
          refresh_after :: integer(),
          refresh_amount :: integer() | nil
        ) :: :ok | {:error, :bucket_not_found}
  def manual_deplete(bucket, refresh_after, refresh_amount \\ nil) do
    GenServer.cast(BucketRegistry, {:manual_deplete, bucket, refresh_after, refresh_amount})
  end

  @doc """
  Returns current bucket state.

  ## Parameters

  - bucket: The name of the bucket

  ## Examples

      iex> Tobu.inspect("test")
      {:ok, %{available: 9, capacity: 10, refresh_amount: 1, refresh_interval: 1000}}
  """
  @spec inspect(bucket :: binary()) :: {:ok, bucket()}
  def inspect(bucket) do
    GenServer.call(BucketRegistry, {:inspect, bucket})
  end
end
