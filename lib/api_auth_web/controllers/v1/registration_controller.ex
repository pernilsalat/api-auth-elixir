defmodule ApiAuthWeb.V1.RegistrationController do
  use ApiAuthWeb, :controller

  alias Plug.Conn
  alias ApiAuthWeb.V1.{Responses.TokensJSON, FallbackController}

  plug :put_view, json: TokensJSON
  action_fallback FallbackController

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.create_user(user_params)
    |> case do
      {:ok, _user, conn} ->
        render(conn, :index, tokens: conn.private)

      {:error, changeset, _conn} ->
        %{
          error: :unauthorized,
          message: "Couldn't create user",
          errors: changeset
        }
    end
  end
end
