defmodule ApiAuthWeb.V1.FallbackController do
  use ApiAuthWeb, :controller

  alias Plug.Conn
  alias Ecto.Changeset
  alias ApiAuthWeb.Helpers.ErrorHelpers
  alias ApiAuthWeb.V1.Responses.ErrorResponse

  def call(conn, %{errors: %Changeset{} = changeset} = opts) do
    errors = Changeset.traverse_errors(changeset, &ErrorHelpers.translate_error/1)

    call(conn, Map.put(opts, :errors, errors))
  end

  def call(conn, :not_authenticated) do
    call(conn, %{error: :unauthorized, message: "Not authenticated"})
  end

  def call(conn, {:error, :unauthorized}) do
    call(conn, %{error: :unauthorized})
  end

  @spec call(Conn.t(), any()) :: Conn.t()
  def call(conn, %{error: :unauthorized} = opts) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: struct(ErrorResponse.Unauthorized, opts)})
  end
end
