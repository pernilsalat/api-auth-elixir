defmodule ApiAuthWeb.Pow.Token do
  @type t :: binary()

  alias Plug.Conn
  alias Pow.{Plug, UUID, Config}

  @spec generate() :: t()
  def generate(), do: UUID.generate()

  @spec sign(Conn.t(), t(), Config.t()) :: t()
  def sign(conn, token, config) do
    Plug.sign_token(conn, signing_salt(), token, config)
  end

  @spec verify(Conn.t(), t(), Config.t()) :: {:ok, t()} | :error
  def verify(conn, token, config) do
    Plug.verify_token(conn, signing_salt(), token, config)
  end

  defp signing_salt(), do: Atom.to_string(__MODULE__)
end
