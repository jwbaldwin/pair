defmodule Pair.Recordings.Workers.MeetingNotesWorkerTest do
  use Pair.DataCase, async: true
  use Oban.Testing, repo: Pair.Repo

  alias Pair.Recordings
  alias Pair.Recordings.Services.ExtractMeetingNotes
  alias Pair.Recordings.Workers.MeetingNotesWorker
  alias Pair.Recordings.Workers.MeetingNotesWorker

  import Mimic

  setup :verify_on_exit!

  describe "perform/1" do
    test "successfully generates actions and structured meeting notes" do
      # Create a test recording with transcription
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          transcription: "John and Sarah discussed the project timeline and budget.",
          status: :transcribed
        })

      # Mock Anthropic actions generation
      expected_actions = """
      📌 ACTION ITEMS
      • John — Review project requirements — By Friday
      • Sarah — Prepare budget proposal — Next week

      📋 KEY FACTS
      • Project timeline: 6 weeks
      • Budget range: $50k-75k
      """

      Anthropic
      |> expect(:generate_actions, fn transcription ->
        assert transcription == "John and Sarah discussed the project timeline and budget."
        {:ok, expected_actions}
      end)

      # Mock structured meeting notes extraction
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
        {:ok, expected_meeting_notes}
      end)

      ExtractMeetingNotes
      |> expect(:to_json, fn notes ->
        assert notes == expected_meeting_notes

        %{
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
      end)

      # Perform the job
      job_args = %{"id" => recording.id}
      assert :ok = perform_job(MeetingNotesWorker, job_args)

      # Verify recording was updated with both actions and meeting notes
      updated_recording = Recordings.get_recording!(recording.id)
      assert updated_recording.actions == expected_actions
      assert updated_recording.status == :analyzed

      # Verify meeting notes were stored as JSON
      assert updated_recording.meeting_notes
      {:ok, parsed_notes} = Jason.decode(updated_recording.meeting_notes)
      assert parsed_notes["meeting_metadata"]["primary_topic"] == "Timeline and Budget Discussion"
      assert length(parsed_notes["participants"]) == 2
      assert length(parsed_notes["sections"]) == 2
    end

    test "handles Anthropic API errors gracefully" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          transcription: "Test transcription",
          status: :transcribed
        })

      # Mock Anthropic failure
      Anthropic
      |> expect(:generate_actions, fn _transcription ->
        {:error, "API rate limit exceeded"}
      end)

      # Should not call ExtractMeetingNotes on Anthropic failure
      ExtractMeetingNotes
      |> expect(:call, 0, fn _recording -> {:ok, %MeetingNotes{}} end)

      job_args = %{"id" => recording.id}
      assert {:error, "API rate limit exceeded"} = perform_job(MeetingNotesWorker, job_args)

      # Verify recording status was set to error
      updated_recording = Recordings.get_recording!(recording.id)
      assert updated_recording.status == :error
      assert updated_recording.actions == nil
      assert updated_recording.meeting_notes == nil
    end

    test "handles meeting notes extraction errors gracefully" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          transcription: "Test transcription",
          status: :transcribed
        })

      # Mock successful Anthropic call
      Anthropic
      |> expect(:generate_actions, fn _transcription ->
        {:ok, "Test actions"}
      end)

      # Mock ExtractMeetingNotes failure
      ExtractMeetingNotes
      |> expect(:call, fn _recording ->
        {:error, "Failed to extract structured notes"}
      end)

      job_args = %{"id" => recording.id}

      assert {:error, "Failed to extract structured notes"} =
               perform_job(MeetingNotesWorker, job_args)

      # Verify recording status was set to error
      updated_recording = Recordings.get_recording!(recording.id)
      assert updated_recording.status == :error
    end

    test "handles recording not found" do
      non_existent_id = UUIDv7.generate()

      # Should not call any external services
      Anthropic
      |> expect(:generate_actions, 0, fn _transcription -> {:ok, "actions"} end)

      ExtractMeetingNotes
      |> expect(:call, 0, fn _recording -> {:ok, %MeetingNotes{}} end)

      job_args = %{"id" => non_existent_id}
      assert {:error, :not_found} = perform_job(MeetingNotesWorker, job_args)
    end

    test "handles database update errors" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          transcription: "Test transcription",
          status: :transcribed
        })

      Anthropic
      |> expect(:generate_actions, fn _transcription ->
        {:ok, "Test actions"}
      end)

      ExtractMeetingNotes
      |> expect(:call, fn _recording ->
        {:ok, %MeetingNotes{sections: [%{title: "Test", type: :other, content: ["test"]}]}}
      end)

      ExtractMeetingNotes
      |> expect(:to_json, fn _notes ->
        %{sections: [%{title: "Test", type: :other, content: ["test"]}]}
      end)

      # Mock Recordings.update_recording to fail
      Recordings
      |> expect(:update_recording, fn _recording, _attrs ->
        {:error, %Ecto.Changeset{}}
      end)

      job_args = %{"id" => recording.id}
      assert {:error, %Ecto.Changeset{}} = perform_job(MeetingNotesWorker, job_args)
    end
  end

  describe "enqueue/1" do
    test "creates actions job with correct arguments" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/test.wav",
          transcription: "Test transcription"
        })

      assert %Oban.Job{} = job = MeetingNotesWorker.enqueue(recording)
      assert job.args == %{"id" => recording.id}
      assert job.worker == "Pair.Recordings.Workers.MeetingNotesWorker"
    end

    test "job is properly inserted into the database" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/test.wav",
          transcription: "Test transcription"
        })

      assert {:ok, job} = MeetingNotesWorker.enqueue(recording)

      # Verify job exists in database
      assert Oban.Job |> Pair.Repo.get!(job.id)
    end
  end

  describe "integration test" do
    test "full actions workflow with both legacy and structured outputs" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          transcription: "Alice and Bob discussed wedding photography packages and pricing.",
          status: :transcribed
        })

      # Mock complete successful workflow
      Anthropic
      |> expect(:generate_actions, fn _transcription ->
        {:ok, "Wedding planning action items generated"}
      end)

      wedding_notes = %MeetingNotes{
        meeting_metadata: %{
          meeting_type: "Client Consultation",
          primary_topic: "Wedding Photography"
        },
        participants: [
          %{name: "Alice Johnson", role: "Bride", initials: "AJ"},
          %{name: "Bob Smith", role: "Photographer", initials: "BS"}
        ],
        sections: [
          %{
            title: "Package Options",
            type: :overview,
            content: ["Premium package discussed", "Custom add-ons available"]
          },
          %{
            title: "Timeline",
            type: :timeline,
            content: ["Wedding date: July 15th", "Engagement shoot: May 20th"]
          },
          %{
            title: "Budget",
            type: :budget,
            content: ["Premium package: $3,500", "Second photographer: +$800"]
          }
        ]
      }

      ExtractMeetingNotes
      |> expect(:call, fn _recording -> {:ok, wedding_notes} end)

      ExtractMeetingNotes
      |> expect(:to_json, fn _notes ->
        %{
          meeting_metadata: %{
            meeting_type: "Client Consultation",
            primary_topic: "Wedding Photography"
          },
          participants: [
            %{name: "Alice Johnson", role: "Bride", initials: "AJ"},
            %{name: "Bob Smith", role: "Photographer", initials: "BS"}
          ],
          sections: [
            %{title: "Package Options", type: :overview, content: ["Premium package discussed"]},
            %{title: "Timeline", type: :timeline, content: ["Wedding date: July 15th"]},
            %{title: "Budget", type: :budget, content: ["Premium package: $3,500"]}
          ]
        }
      end)

      # Enqueue and perform the job
      job = MeetingNotesWorker.enqueue(recording)
      assert :ok = perform_job(MeetingNotesWorker, job.args)

      # Verify complete workflow results
      final_recording = Recordings.get_recording!(recording.id)
      assert final_recording.actions == "Wedding planning action items generated"
      assert final_recording.status == :analyzed
      assert final_recording.meeting_notes

      # Verify structured meeting notes
      {:ok, meeting_notes_json} = Jason.decode(final_recording.meeting_notes)
      assert meeting_notes_json["meeting_metadata"]["primary_topic"] == "Wedding Photography"
      assert length(meeting_notes_json["participants"]) == 2
      assert length(meeting_notes_json["sections"]) == 3

      # Verify timeline section contains wedding date
      timeline_section = Enum.find(meeting_notes_json["sections"], &(&1["title"] == "Timeline"))
      assert timeline_section
      assert "Wedding date: July 15th" in timeline_section["content"]
    end
  end
end
