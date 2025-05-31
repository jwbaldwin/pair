defmodule Pair.Recordings.Services.MeetingNotesExtractorTest do
  @moduledoc """
  Basic test for the MeetingNotesExtractor service.
  """

  alias Pair.Recordings.Services.MeetingNotesExtractor
  alias Pair.Prompts.Schemas.MeetingNotes

  def test_json_conversion do
    # Create a sample MeetingNotes struct
    sample_notes = %MeetingNotes{
      meeting_metadata: %{
        timestamp: "2024-05-31 17:30:00",
        duration_minutes: 30,
        meeting_type: "Product Planning",
        primary_topic: "CRM Integration"
      },
      participants: [
        %{name: "John Doe", role: "Product Manager", initials: "JD"},
        %{name: "Sarah Smith", role: "Marketing Lead", initials: "SS"}
      ],
      sections: [
        %{
          title: "Product Overview",
          type: :overview,
          content: ["Discussing new CRM integration features", "Focus on Salesforce and HubSpot"]
        },
        %{
          title: "Action Items",
          type: :action_items,
          content: ["Review API documentation", "Schedule follow-up meeting"]
        }
      ]
    }

    # Test JSON conversion
    json_result = MeetingNotesExtractor.to_json(sample_notes)

    IO.puts("Sample meeting notes JSON structure:")
    IO.puts(Jason.encode!(json_result, pretty: true))

    json_result
  end
end
