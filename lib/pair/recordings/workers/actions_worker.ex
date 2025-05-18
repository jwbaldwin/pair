defmodule Pair.Recordings.Workers.ActionsWorker do
  @moduledoc """
  Worker to send a transcription plus system prompt to OpenAI for insights.
  """
  use Oban.Worker

  alias Pair.Recordings
  alias Pair.Recordings.Recording
  alias Pair.Clients.Anthropic

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    Logger.info("Generating actions for recording #{id}")

    with {:ok, recording} <- Recordings.fetch_recording(id),
         {:ok, actions} <- Anthropic.generate_actions(recording.transcription) do
      Recordings.update_recording(recording, %{actions: actions})
    end
  end

  @doc """
  Enqueue a transcription job for the given upload_url.
  Worker will send the recording to OpenAI for transcription.
  """
  @spec enqueue(Recording.t()) :: Oban.Job.t()
  def enqueue(recording) do
    %{id: recording.id}
    |> new()
    |> Oban.insert()
  end
end
