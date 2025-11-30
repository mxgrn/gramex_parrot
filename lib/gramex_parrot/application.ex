defmodule GramexParrot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GramexParrotWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:gramex_parrot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GramexParrot.PubSub},
      # Start a worker by calling: GramexParrot.Worker.start_link(arg)
      # {GramexParrot.Worker, arg},
      GramexParrot.TelegramBot,
      # Start to serve requests, typically the last entry
      GramexParrotWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GramexParrot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GramexParrotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
