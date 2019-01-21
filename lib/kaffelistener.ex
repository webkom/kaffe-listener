require Logger

defmodule KaffeListener do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      {KaffeListener.StateServer, name: KaffeListener.StateServer},
      {Tortoise.Connection,
        [
          client_id: "KaffeListenerElixir#{:rand.uniform(1_000_000_000)}",
          server: {Tortoise.Transport.Tcp, host: System.get_env("MQTT_HOST"), port: String.to_integer(System.get_env("MQTT_PORT"))},
          handler: {KaffeListener.MQTTHandler, []},
          user_name: System.get_env("MQTT_USERNAME"),
          password: System.get_env("MQTT_PASSWORD"),
          subscriptions: [
            {"kaffe_tracker/#", 0},
            {"kaffe_register/#", 0}
          ]
        ]}
    ]
    Logger.info "start app"

    opts = [strategy: :one_for_one, name: KaffeListener.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def hello do
    :world
  end
end
