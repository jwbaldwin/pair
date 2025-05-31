defmodule Pair.Recordings.Workers.ActionsWorker do
  @moduledoc """
  Worker to process transcriptions and generate both insights and structured meeting notes.
  This worker handles the analysis phase after transcription is complete.
  """
  use Oban.Worker

  alias Pair.Recordings
  alias Pair.Recordings.Recording
  alias Pair.Clients.Anthropic
  alias Pair.Recordings.Services.MeetingNotesExtractor

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    Logger.info("Generating actions and meeting notes for recording #{id}")

    with {:ok, recording} <- Recordings.fetch_recording(id),
         {:ok, actions} <- Anthropic.generate_actions(recording.transcription),
         {:ok, structured_notes} <-
           MeetingNotesExtractor.extract_meeting_notes(recording.transcription) do
      # Convert structured notes to JSON for storage
      meeting_notes_json =
        structured_notes
        |> MeetingNotesExtractor.to_json()
        |> Jason.encode!()

      Recordings.update_recording(recording, %{
        actions: actions,
        meeting_notes: meeting_notes_json,
        status: :analyzed
      })
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
