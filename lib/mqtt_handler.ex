require Logger

defmodule KaffeListener.MQTTHandler do
  use Tortoise.Handler

  def init(args) do
    {:ok, %{}}
  end

  def connection(status, state) do
    Logger.info "connection is #{status}"
    {:ok, state}
  end

  #  topic filter kaffe_tracker/measurement
  def handle_message(["kaffe_tracker", "measurement"], payload, state) do
    data = Poison.decode! payload
    power_mw = data["emeter"]["get_realtime"]["power_mw"]

    Logger.info "Sending add request from PID #{inspect self()}"
    KaffeListener.StateServer.add_value(power_mw, DateTime.utc_now)

    {:ok, state}
  end

  def handle_message(["kaffe_register", "read_card"], payload, state) do
    Logger.info "kaffe_register/read_card #{payload}"
    data = Poison.decode! payload
    Logger.info data["uid"]
    uid = data["uid"]
    KaffeListener.StateServer.register_card(uid)
    {:ok, state}
  end

  def handle_message(topic, payload, state) do
    Logger.info "unhandled topic #{inspect topic}"
    {:ok, state}
  end

  def subscription(status, topic_filter, state) do
    Logger.info "subscription #{status} '#{topic_filter}'"
    {:ok, state}
  end

  def terminate(reason, state) do
    Logger.info "Terminate with reason: #{inspect reason}"
    :ok
  end
end