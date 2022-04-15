defmodule SchmerdlePhoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      SchmerdlePhoenix.Repo,
      # Start the Telemetry supervisor
      SchmerdlePhoenixWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: SchmerdlePhoenix.PubSub},
      # Start the Endpoint (http/https)
      SchmerdlePhoenixWeb.Endpoint
      # Start a worker by calling: SchmerdlePhoenix.Worker.start_link(arg)
      # {SchmerdlePhoenix.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SchmerdlePhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SchmerdlePhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
