defmodule Pair.Recordings.Workers.MeetingNotesWorker do
  @moduledoc """
  Worker to process transcriptions and generate structured meeting notes.
  This worker handles the analysis phase after transcription is complete.
  """
  use Oban.Worker

  alias Pair.Recordings
  alias Pair.Recordings.Recording
  alias Pair.Recordings.Services.ExtractMeetingNotes

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    Logger.info("Generating meeting notes for recording #{id}")

    with {:ok, recording} <- Recordings.fetch_recording(id),
         {:ok, meeting_notes} <- ExtractMeetingNotes.call(recording) do
      Recordings.update_recording(recording, %{
        meeting_notes: meeting_notes,
        status: :structured
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
