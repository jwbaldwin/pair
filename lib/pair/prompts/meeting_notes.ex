defmodule Pair.Prompts.Schemas.MeetingNotes do
  @moduledoc """
  Ecto schema for structured meeting notes extracted from transcripts using InstructorEx.
  This schema defines the structure for AI-extracted meeting insights and is used
  purely for prompt engineering - it's not stored as an embedded schema in the database.

  The LLM uses this schema to understand what structure to return, then we convert
  the result to JSON for storage in the recordings table.
  """

  use Ecto.Schema
  use Instructor.Validator

  @llm_doc """
  ## Field Descriptions:
  - meeting_metadata: Basic information about the meeting including timestamp, duration, and primary topic
  - participants: List of meeting participants identified from the transcript with names, roles, and initials
  - sections: Main content sections with structured insights organized by type (overview, features, integrations, etc.)
  """

  @primary_key false
  embedded_schema do
    embeds_one :meeting_metadata, MeetingMetadata, primary_key: false do
      field :timestamp, :string
      field :duration_minutes, :integer
      field :meeting_type, :string
      field :primary_topic, :string
    end

    embeds_many :participants, Participant, primary_key: false do
      field :name, :string
      field :role, :string
      field :initials, :string
    end

    embeds_many :sections, Section, primary_key: false do
      field :title, :string

      field :type, Ecto.Enum,
        values: [
          :overview,
          :key_points,
          :decisions,
          :action_items,
          :next_steps,
          :questions,
          :requirements,
          :concerns,
          :timeline,
          :budget,
          :other
        ]

      field :content, {:array, :string}
    end
  end

  # TODO: lost validations
end
