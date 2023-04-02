defmodule ApiAuthWeb.V1.SessionController do
  use ApiAuthWeb, :controller

  alias Plug.Conn
  alias ApiAuthWeb.Pow.AuthPlug
  alias ApiAuthWeb.V1.{Responses, FallbackController}

  plug :put_view, json: Responses.TokensJSON
  action_fallback FallbackController

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.authenticate_user(user_params)
    |> case do
      {:ok, conn} -> render(conn, :index, tokens: conn.private)
      {:error, _conn} -> %{error: :unauthorized, message: "Invalid email or password"}
    end
  end

  @spec renew(Conn.t(), map()) :: Conn.t()
  def renew(conn, _params) do
    config = Pow.Plug.fetch_config(conn)

    conn
    |> AuthPlug.renew(config)
    |> case do
      {_conn, nil} -> %{error: :unauthorized, message: "Invalid token"}
      {conn, _user} -> render(conn, :index, tokens: conn.private)
    end
  end

  @spec delete(Conn.t(), map()) :: Conn.t()
  def delete(conn, _params) do
    conn
    |> Pow.Plug.delete()
    |> send_resp(204, "")
  end
end
