defmodule Pair.Factory do
  @moduledoc """
  Test factories using ExMachina.
  """
  use ExMachina.Ecto, repo: Pair.Repo

  alias Pair.Recordings.Recording

  def recording_factory do
    %Recording{
      upload_url: "test/support/fixtures/recording.wav",
      transcription: %{"text" => "This is a sample transcription"},
      actions: "- Action 1\n- Action 2"
    }
  end
end
