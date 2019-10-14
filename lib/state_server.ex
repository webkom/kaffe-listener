require Logger

defmodule KaffeListener.StateServer do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  # Client API
  def add_value(power, time) do
    GenServer.cast(KaffeListener.StateServer, {:add, power, time})
  end

  def register_card(uid) do
    GenServer.cast(KaffeListener.StateServer, {:card, uid})
  end

  # Server side
  def init(:ok) do
    schedule_ping()

    {:ok,
     %{
       power_history: [],
       last_card: %{uid: "", username: "", time: DateTime.utc_now()}
     }}
  end

  defp schedule_ping do
    Process.send_after(self(), :ping, 5000)
  end

  def handle_cast({:add, power, time}, %{power_history: power_history} = state) do
    Logger.info(
      "Received add request. Power history length #{length(power_history) + 1}. Current level #{
        power
      }"
    )

    {:noreply, %{state | power_history: [{power, time} | power_history]}}
  end

  def handle_cast({:card, uid}, state) do
    Logger.info("Received card request. UID #{inspect(uid)}")

    case KaffeListener.Members.search(uid) do
      {:error, reason} ->
        Logger.error("Failed finding member with reason #{reason}")
        {:noreply, state}

      member ->
        Logger.info("member #{inspect(member)}")
        slack = member["slack"]
        KaffeListener.Slack.register_brewing(slack)
        {:noreply, %{state | last_card: %{uid: uid, username: slack, time: DateTime.utc_now()}}}
    end
  end

  def power_value(ma) when ma > 1_000_000, do: :brewing
  def power_value(ma) when ma > 10_000, do: :heating
  def power_value(ma), do: :off

  def notify_mqtt(uid, volume) do
    payload =
      Poison.encode!(%{
        uid: uid,
        volume: volume
      })

    Tortoise.publish(KaffeListener.get_client_id(), "kaffe_brew_finished", payload)
  end

  def handle_info(:ping, %{power_history: power_history, last_card: last_card} = state) do
    schedule_ping()

    currently_brewing =
      power_history
      |> Enum.take(6)
      |> Enum.map(&elem(&1, 0))
      |> Enum.map(&power_value/1)
      |> Enum.filter(&(&1 == :brewing))
      |> Enum.count()
      |> Kernel.>(0)

    Logger.info("Currently brewing: #{inspect(currently_brewing)}")

    brew_history =
      power_history
      |> Enum.map(fn {power, time} -> {power_value(power), time} end)
      |> Enum.filter(fn {power_value, time} -> power_value == :brewing end)

    if !currently_brewing do
      if length(brew_history) >= 10 do
        brew_time =
          DateTime.diff(
            brew_history |> Enum.at(0) |> elem(1),
            brew_history |> Enum.at(-1) |> elem(1)
          )

        brew_volume = Float.round(0.00522 * brew_time - 0.3226, 1)
        Logger.info("Brew time #{inspect(brew_time)}")
        Logger.info("Brew volume #{inspect(brew_volume)}")
        # If card was registered up to 15 mins before brewing started
        Logger.info(
          "Diff between user and brew #{
            DateTime.diff(brew_history |> Enum.at(0) |> elem(1), last_card.time)
          }"
        )

        if DateTime.diff(brew_history |> Enum.at(-1) |> elem(1), last_card.time) < 60 * 15 and
             last_card.username != "" do
          KaffeListener.Slack.register_brew_finished(brew_volume, last_card.username)
          notify_mqtt(last_card.uid, brew_volume)
        else
          KaffeListener.Slack.register_brew_finished(brew_volume)
          notify_mqtt(nil, brew_volume)
        end
      end

      {:noreply, %{state | power_history: []}}
    else
      if length(brew_history) == 3 and (last_card.username == "" or DateTime.diff(DateTime.utc_now(), last_card.time) > 60 * 15) do
        KaffeListener.Slack.remind_about_card()
      end

      {:noreply, state}
    end
  end
end
