defmodule ApiAuth.UsersTest do
  use ApiAuth.DataCase

  alias ApiAuth.Users

  describe "users" do
    alias ApiAuth.Users.User

    import ApiAuth.UsersFixtures

    @password "secret1234"
    @invalid_attrs %{}
    @valid_attrs %{
      "email" => "test@example.com",
      "password" => @password,
      "password_confirmation" => @password
    }

    test "list_users/0 returns all users" do
      user = user_fixture(@valid_attrs)
      assert Users.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture(@valid_attrs)
      assert Users.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = _user} = Users.create_user(@valid_attrs)
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Users.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture(@valid_attrs)

      update_attrs = %{
        "current_password" => @password,
        "password" => "invalid-password",
        "password_confirmation" => "invalid-password"
      }

      assert {:ok, %User{} = _user} = Users.update_user(user, update_attrs)
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture(@valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Users.update_user(user, @invalid_attrs)
      assert user == Users.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture(@valid_attrs)
      assert {:ok, %User{}} = Users.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Users.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture(@valid_attrs)
      assert %Ecto.Changeset{} = Users.change_user(user)
    end
  end
end
