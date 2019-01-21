require Logger

defmodule KaffeListener.Slack do
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
    body = Poison.encode!(%{
      "text": message,
      "username": "kaffe",
      "channel": "#kaffe",
      "icon_emoji": ":coffee:"
    })
    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: _body}} ->
        :ok
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
