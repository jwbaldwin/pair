defmodule Pair.Recordings.Services.ExtractMeetingNotesTest do
  use Pair.DataCase, async: true

  alias Pair.Recordings.Services.ExtractMeetingNotes
  alias Pair.Prompts.MeetingNotes
  alias Pair.Recordings.Recording

  import Mimic

  setup :verify_on_exit!

  describe "call/1" do
    test "successfully extracts meeting notes from transcript" do
      expected_notes = %MeetingNotes{
        meeting_metadata: %{
          timestamp: "2024-05-31 17:30:00",
          duration_minutes: 30,
          meeting_type: "Client Meeting",
          primary_topic: "Project Planning"
        },
        participants: [
          %{name: "John Doe", role: "Client", initials: "JD"},
          %{name: "Jane Smith", role: "Developer", initials: "JS"}
        ],
        sections: [
          %{
            title: "Overview",
            type: :overview,
            content: ["Discussing new web application project", "Requirements gathering session"]
          },
          %{
            title: "Action Items",
            type: :action_items,
            content: ["Send project proposal by Friday", "Schedule follow-up meeting"]
          }
        ]
      }

      Instructor
      |> expect(:chat_completion, fn opts ->
        assert opts[:model] == "claude-sonnet-4-20250514"
        assert opts[:response_model] == MeetingNotes
        assert opts[:max_retries] == 3
        assert length(opts[:messages]) == 2

        system_message = Enum.find(opts[:messages], &(&1.role == "system"))
        assert system_message
        assert String.contains?(system_message.content, "expert meeting assistant")

        user_message = Enum.find(opts[:messages], &(&1.role == "user"))
        assert user_message
        assert String.contains?(user_message.content, "test transcript content")

        {:ok, expected_notes}
      end)

      recording = %Recording{
        id: "test-id",
        transcription: "test transcript content"
      }

      string_expected_notes = Jason.encode!(ExtractMeetingNotes.to_json(expected_notes))
      assert {:ok, ^string_expected_notes} = ExtractMeetingNotes.call(recording)
    end

    test "handles API errors gracefully" do
      Instructor
      |> expect(:chat_completion, fn _opts ->
        {:error, "API rate limit exceeded"}
      end)

      recording = %Recording{
        id: "test-id",
        transcription: "test transcript"
      }

      assert {:error, "API rate limit exceeded"} = ExtractMeetingNotes.call(recording)
    end

    test "handles exceptions gracefully" do
      Instructor
      |> expect(:chat_completion, fn _opts ->
        raise "Network timeout"
      end)

      recording = %Recording{
        id: "test-id",
        transcription: "test transcript"
      }

      log =
        capture_log(fn ->
          assert {:error, error_msg} = ExtractMeetingNotes.call(recording)
          assert String.contains?(error_msg, "Failed to extract meeting notes")
        end)

      assert log =~ "Error extracting meeting notes: %RuntimeError{message: \"Network timeout\"}"
    end
  end

  describe "to_json/1" do
    test "converts MeetingNotes struct to JSON-string" do
      meeting_notes = %MeetingNotes{
        meeting_metadata: %{
          timestamp: "2024-05-31 17:30:00",
          duration_minutes: 45,
          meeting_type: "Sales Call",
          primary_topic: "SaaS Demo"
        },
        participants: [
          %{name: "Alice Cooper", role: "Sales Rep", initials: "AC"},
          %{name: "Bob Wilson", role: "Prospect", initials: "BW"}
        ],
        sections: [
          %{
            title: "Key Points",
            type: :key_points,
            content: ["Product demo went well", "Customer interested in enterprise features"]
          },
          %{
            title: "Next Steps",
            type: :next_steps,
            content: ["Send pricing proposal", "Schedule technical review"]
          }
        ]
      }

      result = ExtractMeetingNotes.to_json(meeting_notes)

      assert result == %{
               meeting_metadata: %{
                 meeting_type: "Sales Call",
                 primary_topic: "SaaS Demo"
               },
               participants: [
                 %{name: "Alice Cooper", role: "Sales Rep"},
                 %{name: "Bob Wilson", role: "Prospect"}
               ],
               sections: [
                 %{
                   title: "Key Points",
                   type: :key_points,
                   content: [
                     "Product demo went well",
                     "Customer interested in enterprise features"
                   ]
                 },
                 %{
                   title: "Next Steps",
                   type: :next_steps,
                   content: ["Send pricing proposal", "Schedule technical review"]
                 }
               ]
             }
    end

    test "handles nil meeting_metadata" do
      meeting_notes = %MeetingNotes{
        meeting_metadata: nil,
        participants: [],
        sections: [
          %{title: "Test", type: :other, content: ["test"]}
        ]
      }

      result = ExtractMeetingNotes.to_json(meeting_notes)
      assert result.meeting_metadata == nil
    end

    test "handles empty participants and sections" do
      meeting_notes = %MeetingNotes{
        meeting_metadata: %{primary_topic: "Test"},
        participants: nil,
        sections: nil
      }

      result = ExtractMeetingNotes.to_json(meeting_notes)
      assert result.participants == []
      assert result.sections == []
    end
  end
end
