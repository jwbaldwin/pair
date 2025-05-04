defmodule Pair.RecordingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pair.Recordings` context.
  """

  @doc """
  Generate a recording.
  """
  def recording_fixture(attrs \\ %{}) do
    {:ok, recording} =
      attrs
      |> Enum.into(%{
        actions: "- test action",
        transcription: "this is a test transcription",
        upload_url: "https://example.com/audio.wav"
      })
      |> Pair.Recordings.create_recording()

    recording
  end
end
