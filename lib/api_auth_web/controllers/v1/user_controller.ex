defmodule ApiAuthWeb.V1.UserController do
  use ApiAuthWeb, :controller

  def show(conn, _opts) do
    conn
    |> json(%{data: conn.assigns.current_user})
  end
end
