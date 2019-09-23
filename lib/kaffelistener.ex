require Logger

defmodule KaffeListener do
  use Application

  # Random number generated at runtime, used for client_id
  @rand :rand.uniform(1_000_000_000)

  def get_client_id do
    "KaffeListenerElixir#{@rand}"
  end

  def start(_type, _args) do
    import Supervisor.Spec

    Logger.info("client_id: #{get_client_id()}")

    children = [
      {KaffeListener.StateServer, name: KaffeListener.StateServer},
      {Tortoise.Connection,
       [
         name: KaffeListener.MQTTHandler,
         client_id: get_client_id(),
         server: {
           Tortoise.Transport.Tcp,
           host: Application.get_env(:kaffelistener, :mqtt_host),
           port: Application.get_env(:kaffelistener, :mqtt_port)
         },
         handler: {KaffeListener.MQTTHandler, []},
         user_name: Application.get_env(:kaffelistener, :mqtt_username),
         password: Application.get_env(:kaffelistener, :mqtt_password),
         subscriptions: [
           {"kaffe_tracker/#", 0},
           {"kaffe_register/#", 0}
         ]
       ]}
    ]

    Logger.info("start app")

    opts = [strategy: :one_for_one, name: KaffeListener.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def hello do
    :world
  end
end
