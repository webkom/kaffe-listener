require Logger
require Integer

defmodule KaffeListener.Slack do
  def user(%{member: ""}), do: "Ingen brygger registrert"
  def user(%{member: member}), do: "Brygger: <@#{member}>"

  def volume(%{brewing: false}), do: "Brygging har ikke startet"

  def hourglass(%{counter: n}) when Integer.is_odd(n) do
    ":hourglass_flowing_sand:"
  end

  def hourglass(%{counter: n}) when Integer.is_even(n) do
    ":hourglass:"
  end

  def volume(%{volume: volume} = status),
    do: "#{hourglass(status)} Volum #{volume} #{hourglass(status)}\n#{progress(volume)}"

  def progress(n), do: String.duplicate("█", round(n / 0.1))

  def message(status) do
    """
    ============
    #{user(status)}
    #{volume(status)}
    ============
    """
  end

  def start_brew(status) do
    Logger.info("start_brew")
    msg = message(status)

    case Slack.Web.Chat.post_message(Application.get_env(:slack, :channel), msg, %{
           username: "kaffe",
           icon_emoji: ":coffee:"
         }) do
      %{"message" => %{"ts" => ts}} -> ts
    end
  end

  def update_brew(brew_id, status) do
    Logger.info("update_brew #{brew_id}: #{inspect(status)}")
    msg = message(status)
    %{"ok" => true} = Slack.Web.Chat.update(Application.get_env(:slack, :channel), msg, brew_id)
  end

  def register_brewing(username) do
    send("<@#{username}> brygger kaffe :sunglasses:")
  end

  def register_brew_finished(volume) do
    send("Ukjent brygget #{volume} liter kaffe")
  end

  def register_brew_finished(volume, username) do
    send("<@#{username}> brygget #{volume} liter kaffe")
  end

  def send(message) do
    url = System.get_env("SLACK_URL")
    headers = ["Content-Type": "application/json"]

    body =
      Poison.encode!(%{
        text: message,
        username: "kaffe",
        channel: "#kaffe",
        icon_emoji: ":coffee:"
      })

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body}} ->
        :ok

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
