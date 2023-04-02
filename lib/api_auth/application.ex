defmodule ApiAuth.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ApiAuthWeb.Telemetry,
      # Start the Ecto repository
      ApiAuth.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: ApiAuth.PubSub},
      # Start the Endpoint (http/https)
      ApiAuthWeb.Endpoint,
      # Start a worker by calling: ApiAuth.Worker.start_link(arg)
      # {ApiAuth.Worker, arg}
      {Redix, name: :redix}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ApiAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ApiAuthWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
