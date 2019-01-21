defmodule KaffeListener.MixProject do
  use Mix.Project

  def project do
    [
      app: :kaffelistener,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {KaffeListener, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tortoise, "~> 0.9.4"},
      {:poison, "~> 3.1"},
      {:httpoison, "~> 1.5"},
      {:distillery, "~> 2.0"}
    ]
  end
end
