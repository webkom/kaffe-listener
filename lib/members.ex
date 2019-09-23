require Logger

defmodule KaffeListener.Members do
  def search(uuid) do
    url = URI.merge(URI.parse(System.get_env("MEMBERS_URL")), "?card=#{uuid}") |> to_string()

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Poison.decode!(body)
        |> Enum.at(0, {:error, :no_results})

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
