defmodule ApiAuthWeb.Router do
  use ApiAuthWeb, :router
  use Pow.Phoenix.Router

  alias Pow.Plug.RequireAuthenticated
  alias ApiAuthWeb.Pow.AuthPlug

  pipeline :api do
    plug :accepts, ["json"]
    plug AuthPlug, otp_app: :api_auth
  end

  pipeline :api_protected do
    plug RequireAuthenticated, error_handler: ApiAuthWeb.V1.FallbackController
  end

  scope "/api/v1", ApiAuthWeb.V1, as: :api_auth_v1 do
    pipe_through :api

    resources "/registration", RegistrationController, singleton: true, only: [:create]
    resources "/session", SessionController, singleton: true, only: [:create, :delete]
    post "/session/renew", SessionController, :renew
  end

  scope "/api/v1", ApiAuthWeb.V1, as: :api_auth_v1 do
    pipe_through [:api, :api_protected]

    scope "/users" do
      get "/current", UserController, :show
    end
  end
end
