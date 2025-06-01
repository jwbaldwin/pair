defmodule Pair.Recordings.Workers.InsightsWorker do
  @moduledoc """
  Worker to process transcriptions and generate insights.
  This worker handles the analysis phase after transcription is complete.
  """
  use Oban.Worker

  alias Pair.Recordings
  alias Pair.Recordings.Recording
  alias Pair.Clients.Anthropic

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    Logger.info("Generating insights for recording #{id}")

    with {:ok, recording} <- Recordings.fetch_recording(id),
         {:ok, actions} <- Anthropic.generate_actions(recording.transcription),
         {:ok, _} = Recordings.update_recording(recording, %{actions: actions, status: :analyzed}) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to process recording #{id}: #{inspect(reason)}")

        with {:ok, recording} <- Recordings.fetch_recording(id) do
          Recordings.update_recording(recording, %{status: :error})
        end

        {:error, reason}
    end
  end

  @doc """
  Enqueue an actions job for the given recording.
  """
  @spec enqueue(Recording.t()) :: Oban.Job.t()
  def enqueue(recording) do
    %{id: recording.id}
    |> new()
    |> Oban.insert()
  end
end
