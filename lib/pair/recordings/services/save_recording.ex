defmodule Pair.Recordings.Services.SaveRecording do
  @moduledoc """
  Service to save a recording to blob storage
  """

  alias Pair.Recordings
  alias Pair.Recordings.Workers.TranscriptionWorker

  @spec call(Plug.Upload.t()) :: Pair.Recordings.Recording.t()
  def call(%Plug.Upload{} = recording) do
    short_id = :crypto.strong_rand_bytes(4) |> Base.encode16()
    filename = short_id <> "_" <> recording.filename
    :ok = File.cp!(recording.path, "uploads/#{filename}")

    with {:ok, recording} <- Recordings.create_recording(%{upload_url: "uploads/#{filename}"}),
         :ok <- TranscriptionWorker.enqueue(recording) do
      {:ok, recording}
    end
  end
end
