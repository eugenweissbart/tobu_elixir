defmodule TobuTest do
  use ExUnit.Case

  setup do
    start_supervised!({Tobu.BucketRegistry, Application.get_all_env(:tobu)})

    :ok
  end

  describe "new_bucket" do
    test "creates a new bucket" do
      assert :ok = Tobu.new_bucket(:test)

      assert :ok =
               Tobu.new_bucket(:test2, capacity: 20, refresh_interval: 2000, refresh_amount: 2)

      assert %{
               timers: %{
                 test: {:interval, _},
                 test2: {:interval, _}
               },
               buckets: %{
                 test: %{
                   available: 10,
                   capacity: 10,
                   refresh_amount: 1,
                   refresh_interval: 1000
                 },
                 test2: %{
                   available: 20,
                   capacity: 20,
                   refresh_amount: 2,
                   refresh_interval: 2000
                 }
               }
             } = :sys.get_state(Tobu.BucketRegistry)
    end
  end

  describe "get" do
    test "returns an error if the bucket does not exist" do
      assert {:error, :bucket_not_found} = Tobu.get(:test, 1)
    end

    test "returns an error if the amount is greater than the capacity" do
      Tobu.new_bucket(:test)

      assert {:error, %{available: 10, capacity: 10, refresh_amount: 1, refresh_interval: 1000}} =
               Tobu.get(:test, 11)
    end

    test "returns an ok-tuple including current bucket state" do
      Tobu.new_bucket(:test)

      assert {:ok, %{available: 9, capacity: 10, refresh_amount: 1, refresh_interval: 1000}} =
               Tobu.get(:test, 1)
    end
  end

  describe "get_or_create" do
    test "returns an error if the amount is greater than the capacity" do
      assert {:error, %{available: 10, capacity: 10, refresh_amount: 1, refresh_interval: 1000}} =
               Tobu.get_or_create(:test, 11,
                 capacity: 10,
                 refresh_interval: 1000,
                 refresh_amount: 1
               )
    end

    test "returns an ok-tuple including current bucket state" do
      assert {:ok, %{available: 9, capacity: 10, refresh_amount: 1, refresh_interval: 1000}} =
               Tobu.get_or_create(:test, 1,
                 capacity: 10,
                 refresh_interval: 1000,
                 refresh_amount: 1
               )
    end
  end

  describe "inspect" do
    test "returns an ok-tuple including current bucket state" do
      Tobu.new_bucket(:test)

      assert {:ok, %{available: 9, capacity: 10, refresh_amount: 1, refresh_interval: 1000}} =
               Tobu.get(:test, 1)

      assert {:ok, %{available: 9, capacity: 10, refresh_amount: 1, refresh_interval: 1000}} =
               Tobu.inspect(:test)
    end

    test "returns an error if the bucket does not exist" do
      assert {:error, :bucket_not_found} = Tobu.inspect(:test)
    end
  end

  describe "manual_refresh" do
    test "depletes current bucket and refreshes it after set interval" do
      Tobu.new_bucket(:test)

      assert :ok = Tobu.manual_deplete(:test, 500, 3)

      assert %{
               timers: %{
                 test: nil
               },
               buckets: %{
                 test: %{
                   available: 0
                 }
               }
             } = :sys.get_state(Tobu.BucketRegistry)

      Process.sleep(700)

      assert %{
               timers: %{
                 test: {:interval, _}
               },
               buckets: %{
                 test: %{
                   available: 3
                 }
               }
             } = :sys.get_state(Tobu.BucketRegistry)
    end
  end
end
