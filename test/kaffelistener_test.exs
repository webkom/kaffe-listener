defmodule KaffeListenerTest do
  use ExUnit.Case
  doctest KaffeListener

  test "greets the world" do
    assert KaffeListener.hello() == :world
  end
end
