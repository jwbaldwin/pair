defmodule Pair.Recordings.Services.ExtractMeetingNotes do
  @moduledoc """
  Service for extracting structured meeting notes from a recording transcript
  """

  alias Pair.Prompts.MeetingNotes
  alias Pair.Recordings.Recording
  alias Pair.MeetingTemplates.MeetingTemplate

  require Logger

  @doc @moduledoc
  @spec call(Recording.t(), MeetingTemplate.t() | nil) ::
          {:ok, MeetingNotes.t()} | {:error, any()}
  def call(%Recording{transcription: transcript}, template \\ nil) when is_binary(transcript) do
    Logger.info("Extracting structured meeting notes from transcript")

    with {:ok, notes} <-
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
                 content: build_user_prompt(transcript, template)
               }
             ]
           ) do
      notes
      |> to_json()
      |> Jason.encode!()
      |> then(&{:ok, &1})
    end
  rescue
    error ->
      Logger.error("Error extracting meeting notes: #{inspect(error)}")
      {:error, "Failed to extract meeting notes: #{inspect(error)}"}
  end

  @spec to_json(MeetingNotes.t()) :: map()
  def to_json(%MeetingNotes{} = meeting_notes) do
    %{
      meeting_metadata: format_meeting_metadata(Map.get(meeting_notes, :meeting_metadata)),
      participants: format_participants(Map.get(meeting_notes, :participants)),
      sections: format_sections(Map.get(meeting_notes, :sections))
    }
  end

  defp format_meeting_metadata(nil), do: nil

  defp format_meeting_metadata(metadata) do
    %{
      meeting_type: Map.get(metadata, :meeting_type),
      primary_topic: Map.get(metadata, :primary_topic)
    }
  end

  defp format_participants(participants) when is_list(participants) do
    Enum.map(participants, fn participant ->
      %{
        name: Map.get(participant, :name),
        role: Map.get(participant, :role)
      }
    end)
  end

  defp format_participants(_), do: []

  defp format_sections(sections) when is_list(sections) do
    Enum.map(sections, fn section ->
      %{
        title: Map.get(section, :title),
        type: Map.get(section, :type),
        content: Map.get(section, :content, [])
      }
    end)
  end

  defp format_sections(_), do: []

  defp build_user_prompt(transcript, template) do
    base_prompt = """
    Extract structured meeting notes from this transcript:

    <transcript>
    #{transcript}
    </transcript>

    Please organize the insights into clear sections with relevant bullet points.
    Focus on actionable information and key decisions.
    """

    case template do
      %MeetingTemplate{sections: sections} when is_list(sections) and length(sections) > 0 ->
        sections_text = sections |> Enum.map(&"- #{&1}") |> Enum.join("\n")

        base_prompt <>
          """

          Use these specific sections to organize the content:
          #{sections_text}

          Structure your response using these section titles where relevant content exists.
          """

      _ ->
        base_prompt
    end
  end

  defp system_prompt(template \\ nil) do
    base_prompt = """
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

    case template do
      %MeetingTemplate{description: description} when is_binary(description) ->
        base_prompt <>
          """

          TEMPLATE-SPECIFIC INSTRUCTIONS:
          #{description}
          """

      _ ->
        base_prompt
    end
  end
end
