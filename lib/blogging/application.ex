defmodule Blogging.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BloggingWeb.Telemetry,
      Blogging.Repo,
      {DNSCluster, query: Application.get_env(:blogging, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Blogging.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Blogging.Finch},
      # Start a worker by calling: Blogging.Worker.start_link(arg)
      # {Blogging.Worker, arg},
      # Start to serve requests, typically the last entry
      BloggingWeb.Endpoint,
      Blogging.Presence,
      {Registry, keys: :unique, name: Blogging.PostRegistry},
      Blogging.Tracker.PostSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Blogging.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BloggingWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
