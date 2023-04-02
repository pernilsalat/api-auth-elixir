defmodule ApiAuthWeb.Pow.RedisCacheTest do
  use ExUnit.Case
  doctest ApiAuthWeb.Pow.RedisCache

  alias ApiAuthWeb.Pow.RedisCache

  @default_config [namespace: "test", ttl: :timer.hours(1)]

  setup do
    Redix.command!(:redix, ["FLUSHALL"])

    :ok
  end

  test "can put, get and delete records" do
    assert RedisCache.get(@default_config, "key") == :not_found

    RedisCache.put(@default_config, {"key", "value"})
    assert RedisCache.get(@default_config, "key") == "value"

    RedisCache.delete(@default_config, "key")
    assert RedisCache.get(@default_config, "key") == :not_found
  end

  test "with `writes: :async` config option" do
    config = Keyword.put(@default_config, :writes, :async)

    assert RedisCache.get(config, "key") == :not_found

    RedisCache.put(config, {"key", "value"})
    assert RedisCache.get(config, "key") == :not_found
    :timer.sleep(100)
    assert RedisCache.get(config, "key") == "value"

    RedisCache.delete(config, "key")
    assert RedisCache.get(config, "key") == "value"
    :timer.sleep(100)
    assert RedisCache.get(config, "key") == :not_found
  end

  test "delete removes from redis sets" do
    RedisCache.put(@default_config, {["namespace", "key1"], "value"})
    RedisCache.put(@default_config, {["namespace", "key2"], "value"})
    assert redix_zmembers_decoded("namespace") == ["key1", "key2"]

    RedisCache.delete(@default_config, ["namespace", "key1"])
    assert redix_zmembers_decoded("namespace") == ["key2"]
  end

  describe "with redis errors" do
    setup do
      ["maxmemory", value] = Redix.command!(:redix, ["CONFIG", "GET", "maxmemory"])

      Redix.command!(:redix, ["CONFIG", "SET", "maxmemory", "10"])

      on_exit(fn ->
        Redix.command!(:redix, ["CONFIG", "SET", "maxmemory", value])
      end)
    end

    test "raises error" do
      expected_error_message =
        "Redix received unexpected response [{%Redix.Error{message: \"OOM command not allowed when used memory > 'maxmemory'.\"}, "

      assert_raise RuntimeError, ~r/#{Regex.escape(expected_error_message)}/, fn ->
        RedisCache.put(@default_config, {"key", "value"})
      end
    end
  end

  test "can put multiple records at once" do
    RedisCache.put(@default_config, [{"key1", "1"}, {"key2", "2"}])
    assert RedisCache.get(@default_config, "key1") == "1"
    assert RedisCache.get(@default_config, "key2") == "2"
  end

  test "can match fetch all" do
    assert RedisCache.all(@default_config, :_) == []

    for number <- 1..11, do: RedisCache.put(@default_config, {"key#{number}", "value"})
    items = RedisCache.all(@default_config, :_)

    assert Enum.find(items, fn {key, "value"} -> key == "key1" end)
    assert Enum.find(items, fn {key, "value"} -> key == "key2" end)
    assert length(items) == 11

    RedisCache.put(@default_config, {["namespace", "key"], "value"})
    RedisCache.put(@default_config, {["namespace", "key", "key2"], "value"})
    assert RedisCache.all(@default_config, ["namespace", :_]) == [{["namespace", "key"], "value"}]
  end

  test "records auto purge" do
    config = Keyword.put(@default_config, :ttl, 50)

    RedisCache.put(config, {"key", "value"})
    RedisCache.put(config, [{"key1", "1"}, {["namespace", "key2"], "2"}])
    assert RedisCache.get(config, "key") == "value"
    assert RedisCache.get(config, "key1") == "1"
    assert RedisCache.get(config, ["namespace", "key2"]) == "2"
    assert redix_zmembers_decoded("namespace") == ["key2"]
    RedisCache.put(Keyword.put(@default_config, :ttl, 150), [{["namespace", "key3"], "3"}])
    assert redix_zmembers_decoded("namespace") == ["key2", "key3"]
    :timer.sleep(100)
    assert RedisCache.get(config, "key") == :not_found
    assert RedisCache.get(config, "key1") == :not_found
    assert RedisCache.get(config, ["namespace", "key2"]) == :not_found
    assert RedisCache.get(config, ["namespace", "key3"]) == "3"
    RedisCache.put(Keyword.put(@default_config, :ttl, 100), [{["namespace", "key4"], "4"}])
    assert redix_zmembers_decoded("namespace") == ["key3", "key4"]
    :timer.sleep(100)
    assert RedisCache.get(config, ["namespace", "key3"]) == :not_found
    assert RedisCache.all(config, ["namespace", :_]) == []
    assert redix_zmembers_decoded("namespace") == []
  end

  defp redix_zmembers_decoded(key) do
    encoded_prefix =
      [@default_config[:namespace]]
      |> Kernel.++(List.wrap(key))
      |> Enum.map(fn part ->
        part
        |> :erlang.term_to_binary()
        |> Base.url_encode64(padding: false)
      end)
      |> Enum.join(":")

    :redix
    |> Redix.command!(["ZRANGEBYSCORE", "_index:#{encoded_prefix}", "-inf", "+inf"])
    |> Enum.map(fn encoded_key ->
      encoded_key
      |> String.split(":")
      |> Enum.map(fn part ->
        part
        |> Base.url_decode64!(padding: false)
        |> :erlang.binary_to_term()
      end)
      |> case do
        [key] -> key
        key -> key
      end
    end)
  end
end
