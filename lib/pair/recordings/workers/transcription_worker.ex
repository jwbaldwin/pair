defmodule Pair.Recordings.Workers.TranscriptionWorker do
  @moduledoc """
  Worker to send a recording to OpenAI for transcription and store the result.
  If the transcription is successful, we will enqueue a job to generate insights.
  """
  use Oban.Worker

  alias Pair.Clients.OpenAI
  alias Pair.Recordings
  alias Pair.Recordings.Recording
  alias Pair.Recordings.Workers.ActionsWorker

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "upload_url" => upload_url}}) do
    Logger.info("Transcribing recording at #{id}:#{upload_url}")

    with {:ok, transcription} <- OpenAI.transcribe(upload_url),
         {:ok, recording} <- Recordings.fetch_recording(id),
         {:ok, _} <- Recordings.update_recording(recording, %{transcription: transcription, status: :transcribed}) do
      ActionsWorker.enqueue(recording)
    end
  end

  @doc """
  Enqueue a transcription job for the given upload_url.
  Worker will send the recording to OpenAI for transcription.
  """
  @spec enqueue(Recording.t()) :: Oban.Job.t()
  def enqueue(recording) do
    %{id: recording.id, upload_url: recording.upload_url}
    |> new()
    |> Oban.insert()
  end
end
