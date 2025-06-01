defmodule Pair.Recordings.Workers.MeetingNotesWorkerTest do
  use Pair.DataCase, async: true
  use Oban.Testing, repo: Pair.Repo

  alias Pair.Recordings
  alias Pair.Recordings.Services.ExtractMeetingNotes
  alias Pair.Recordings.Workers.MeetingNotesWorker
  alias Pair.Prompts.MeetingNotes

  import Mimic

  setup :verify_on_exit!

  describe "perform/1" do
    test "successfully generates actions and structured meeting notes" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          transcription: "John and Sarah discussed the project timeline and budget.",
          status: :transcribed
        })

      expected_meeting_notes = %MeetingNotes{
        meeting_metadata: %{
          timestamp: "2024-05-31 17:30:00",
          meeting_type: "Project Planning",
          primary_topic: "Timeline and Budget Discussion"
        },
        participants: [
          %{name: "John Doe", role: "Project Manager", initials: "JD"},
          %{name: "Sarah Smith", role: "Developer", initials: "SS"}
        ],
        sections: [
          %{
            title: "Timeline",
            type: :timeline,
            content: ["Project duration: 6 weeks", "Start date: June 1st"]
          },
          %{
            title: "Budget",
            type: :budget,
            content: ["Budget range: $50k-75k", "Payment in 3 milestones"]
          }
        ]
      }

      ExtractMeetingNotes
      |> expect(:call, fn worker_recording ->
        assert worker_recording.id == recording.id
        {:ok, Jason.encode!(ExtractMeetingNotes.to_json(expected_meeting_notes))}
      end)

      job_args = %{"id" => recording.id}
      assert :ok = perform_job(MeetingNotesWorker, job_args)

      updated_recording = Recordings.get_recording!(recording.id)

      assert updated_recording.meeting_notes
      {:ok, parsed_notes} = Jason.decode(updated_recording.meeting_notes)
      assert parsed_notes["meeting_metadata"]["primary_topic"] == "Timeline and Budget Discussion"
      assert length(parsed_notes["participants"]) == 2
      assert length(parsed_notes["sections"]) == 2
    end

    test "handles meeting notes extraction errors gracefully" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          transcription: "Test transcription",
          status: :transcribed
        })

      ExtractMeetingNotes
      |> expect(:call, fn _recording ->
        {:error, "Failed to extract structured notes"}
      end)

      job_args = %{"id" => recording.id}

      log =
        capture_log(fn ->
          assert {:error, "Failed to extract structured notes"} =
                   perform_job(MeetingNotesWorker, job_args)
        end)

      updated_recording = Recordings.get_recording!(recording.id)

      assert log =~ "Failed to extract structured notes"
      assert updated_recording.status == :error
    end

    test "handles recording not found" do
      non_existent_id = UUIDv7.generate()

      ExtractMeetingNotes
      |> reject(:call, 1)

      job_args = %{"id" => non_existent_id}

      log =
        capture_log(fn ->
          assert {:error, :not_found} = perform_job(MeetingNotesWorker, job_args)
        end)

      assert log =~ "Failed to process recording #{non_existent_id}: :not_found"
    end
  end

  describe "enqueue/1" do
    test "creates actions job with correct arguments" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/test.wav",
          transcription: "Test transcription"
        })

      assert {:ok, %Oban.Job{} = job} = MeetingNotesWorker.enqueue(recording)
      assert job.args == %{id: recording.id}
      assert job.worker == "Pair.Recordings.Workers.MeetingNotesWorker"
    end
  end
end
