defmodule ApiAuth.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :email, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    pow_user_fields()

    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    pow_changeset(user_or_changeset, attrs)
  end
end
