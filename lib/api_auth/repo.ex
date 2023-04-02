defmodule ApiAuth.Repo do
  use Ecto.Repo,
    otp_app: :api_auth,
    adapter: Ecto.Adapters.Postgres

  defoverridable get: 2, get: 3

  def get(query, id, opts \\ []) do
    try do
      super(query, id, opts)
    rescue
      Ecto.Query.CastError -> nil
    end
  end

  defoverridable get!: 2, get!: 3

  def get!(query, id, opts \\ []) do
    case get(query, id, opts) do
      nil -> raise Ecto.NoResultsError.exception(queryable: query)
      resource -> resource
    end
  end
end
