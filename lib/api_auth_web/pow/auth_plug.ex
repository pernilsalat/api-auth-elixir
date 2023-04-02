defmodule ApiAuthWeb.Pow.AuthPlug do
  @moduledoc false
  use Pow.Plug.Base

  alias Plug.Conn
  alias ApiAuthWeb.Pow.Token
  alias Pow.{Config, Store.CredentialsCache}
  alias PowPersistentSession.Store.PersistentSessionCache

  @access_token_config [ttl: :timer.minutes(10)]
  @renew_token_config [ttl: :timer.hours(24 * 30)]

  @doc """
  Fetches the user from access token.
  """
  @impl true
  @spec fetch(Conn.t(), Config.t()) :: {Conn.t(), map() | nil}
  def fetch(conn, config) do
    store_config = store_config(config)

    with {:ok, signed_token} <- fetch_access_token(conn),
         {:ok, token} <- Token.verify(conn, signed_token, config),
         {user, _metadata} <- CredentialsCache.get(store_config, token) do
      {conn, user}
    else
      _any -> {conn, nil}
    end
  end

  @doc """
  Creates an access and renewal token for the user.

  The tokens are added to the `conn.private` as `:api_auth_access_token` and
  `:api_auth_renewal_token`. The renewal token is stored in the access token
  metadata and vice versa.
  """
  @impl true
  @spec create(Conn.t(), map(), Config.t()) :: {Conn.t(), map()}
  def create(conn, user, config) do
    store_config = store_config(config)
    access_token = Token.generate()
    renewal_token = Token.generate()
    signed_access_token = Token.sign(conn, access_token, config)
    signed_renewal_token = Token.sign(conn, renewal_token, config)

    conn =
      conn
      |> Conn.put_private(:api_access_token, signed_access_token)
      |> Conn.put_private(:api_renewal_token, signed_renewal_token)
      |> Conn.register_before_send(fn conn ->
        CredentialsCache.put(
          store_config ++ @access_token_config,
          access_token,
          {user, [renewal_token: renewal_token]}
        )

        PersistentSessionCache.put(
          store_config ++ @renew_token_config,
          renewal_token,
          {user, [access_token: access_token]}
        )

        conn
      end)

    {conn, user}
  end

  @doc """
  Delete the access token from the cache.

  The renewal token is deleted by fetching it from the access token metadata.
  """
  @impl true
  @spec delete(Conn.t(), Config.t()) :: Conn.t()
  def delete(conn, config) do
    store_config = store_config(config)

    with {:ok, signed_token} <- fetch_access_token(conn),
         {:ok, token} <- Token.verify(conn, signed_token, config),
         {_user, metadata} <- CredentialsCache.get(store_config, token) do
      Conn.register_before_send(conn, fn conn ->
        PersistentSessionCache.delete(store_config, metadata[:renewal_token])
        CredentialsCache.delete(store_config, token)

        conn
      end)
    else
      _any -> conn
    end
  end

  @doc """
  Creates new tokens using the renewal token.

  The access token, if any, will be deleted by fetching it from the renewal
  token metadata. The renewal token will be deleted from the store after the
  it has been fetched.
  """
  @spec renew(Conn.t(), Config.t()) :: {Conn.t(), map() | nil}
  def renew(conn, config) do
    store_config = store_config(config)

    with {:ok, signed_token} <- fetch_access_token(conn),
         {:ok, token} <- Token.verify(conn, signed_token, config),
         {user, metadata} <- PersistentSessionCache.get(store_config, token) do
      {conn, user} = create(conn, user, config)

      conn =
        Conn.register_before_send(conn, fn conn ->
          CredentialsCache.delete(store_config, metadata[:access_token])
          PersistentSessionCache.delete(store_config, token)

          conn
        end)

      {conn, user}
    else
      _any -> {conn, nil}
    end
  end

  defp fetch_access_token(conn) do
    case Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> token | _rest] -> {:ok, token}
      _any -> :error
    end
  end

  defp store_config(config) do
    backend = Config.get(config, :cache_store_backend, Pow.Store.Backend.EtsCache)

    [backend: backend, pow_config: config]
  end
end
