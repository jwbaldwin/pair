defmodule Pair.Recordings.Services.ExtractMeetingNotes do
  @moduledoc """
  Service for extracting structured meeting notes from a recording transcript
  """

  alias Pair.Prompts.MeetingNotes
  alias Pair.Recordings.Recording

  require Logger

  @doc @moduledoc
  @spec call(Recording.t()) :: {:ok, MeetingNotes.t()} | {:error, any()}
  def call(%Recording{transcription: transcript}) when is_binary(transcript) do
    Logger.info("Extracting structured meeting notes from transcript")

    Instructor.chat_completion(
      model: "claude-sonnet-4-20250514",
      response_model: MeetingNotes,
      max_retries: 3,
      messages: [
        %{
          role: "system",
          content: system_prompt()
        },
        %{
          role: "user",
          content: """
          Extract structured meeting notes from this transcript:

          <transcript>
          #{transcript}
          </transcript>

          Please organize the insights into clear sections with relevant bullet points.
          Focus on actionable information and key decisions.
          """
        }
      ]
    )
  rescue
    error ->
      Logger.error("Error extracting meeting notes: #{inspect(error)}")
      {:error, "Failed to extract meeting notes: #{inspect(error)}"}
  end

  def extract_meeting_notes(_), do: {:error, "Invalid transcript format"}

  @doc """
  Converts structured meeting notes to a JSON-serializable format.
  """
  @spec to_json(MeetingNotes.t()) :: map()
  def to_json(%MeetingNotes{} = meeting_notes) do
    %{
      meeting_metadata: format_meeting_metadata(meeting_notes.meeting_metadata),
      participants: format_participants(meeting_notes.participants),
      sections: format_sections(meeting_notes.sections)
    }
  end

  defp format_meeting_metadata(nil), do: nil

  defp format_meeting_metadata(metadata) do
    %{
      timestamp: metadata.timestamp,
      duration_minutes: metadata.duration_minutes,
      meeting_type: metadata.meeting_type,
      primary_topic: metadata.primary_topic
    }
  end

  defp format_participants(participants) when is_list(participants) do
    Enum.map(participants, fn participant ->
      %{
        name: participant.name,
        role: participant.role,
        initials: participant.initials
      }
    end)
  end

  defp format_participants(_), do: []

  defp format_sections(sections) when is_list(sections) do
    Enum.map(sections, fn section ->
      %{
        title: section.title,
        type: section.type,
        content: section.content || []
      }
    end)
  end

  defp format_sections(_), do: []

  defp system_prompt do
    """
    You are an expert meeting assistant that extracts structured insights from meeting transcripts.

    Your task is to:
    1. Identify key participants and their roles from the conversation
    2. Extract the main topics and organize them into logical sections
    3. Summarize key points, decisions, and action items
    4. Create clear, actionable bullet points for each section
    5. Infer meeting metadata when possible

    Focus on creating sections that apply to any professional context:
    - **Overview**: Main topic, purpose, or subject being discussed
    - **Key Points**: Important information, capabilities, or concepts discussed  
    - **Decisions**: Concrete outcomes, agreements, or resolutions reached
    - **Action Items**: Next steps with clear ownership and responsibilities
    - **Requirements**: Specifications, needs, or criteria mentioned
    - **Concerns**: Risks, challenges, or potential issues raised
    - **Timeline**: Dates, deadlines, or scheduling information
    - **Budget**: Financial discussions, pricing, or cost considerations

    Guidelines:
    - Keep bullet points concise but informative (10-20 words max per point)
    - Extract participant names and roles accurately from the transcript
    - Infer meeting type when possible from context
    - Use "other" section type for content that doesn't fit standard categories
    - Focus on actionable and memorable information
    - If no clear participants are identified, you may leave the participants array empty
    - Always create at least one section with relevant content

    Be accurate and don't invent information that isn't present in the transcript.
    """
  end
end
