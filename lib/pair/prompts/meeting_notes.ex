defmodule Pair.Prompts.MeetingNotes do
  @moduledoc """
  Ecto schema for structured meeting notes extracted from transcripts using InstructorEx.
  This schema defines the structure for AI-extracted meeting insights and is used
  purely for prompt engineering - it's not stored as an embedded schema in the database.

  The LLM uses this schema to understand what structure to return, then we convert
  the result to JSON for storage in the recordings table.
  """

  use Ecto.Schema
  use Instructor.Validator

  @type t :: %__MODULE__{}

  @llm_doc """
  ## Field Descriptions:
  - meeting_metadata: Basic information about the meeting including timestamp, duration, and primary topic
  - participants: List of meeting participants identified from the transcript with names, roles, and initials
  - sections: Main content sections with structured insights organized by type (overview, features, integrations, etc.)
  """
  @primary_key false
  embedded_schema do
    embeds_one :meeting_metadata, MeetingMetadata, primary_key: false do
      field :meeting_type, :string
      field :primary_topic, :string
    end

    embeds_many :participants, Participant, primary_key: false do
      field :name, :string
      field :role, :string
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

  @impl true
  def validate_changeset(changeset) do
    changeset
    |> Ecto.Changeset.validate_required([:sections])
    |> Ecto.Changeset.validate_length(:sections, min: 1)
    |> validate_participants()
    |> validate_sections()
  end

  defp validate_participants(changeset) do
    case Ecto.Changeset.get_field(changeset, :participants) do
      nil ->
        changeset

      participants ->
        participants
        |> Enum.with_index()
        |> Enum.reduce(changeset, fn {_participant, index}, acc ->
          acc
          |> Ecto.Changeset.validate_required([{:participants, index, :name}])
          |> Ecto.Changeset.validate_length({:participants, index, :name}, min: 1, max: 100)
        end)
    end
  end

  defp validate_sections(changeset) do
    case Ecto.Changeset.get_field(changeset, :sections) do
      nil ->
        changeset

      sections ->
        sections
        |> Enum.with_index()
        |> Enum.reduce(changeset, fn {_section, index}, acc ->
          acc
          |> Ecto.Changeset.validate_required([{:sections, index, :title}])
          |> Ecto.Changeset.validate_length({:sections, index, :title}, min: 1, max: 200)
          |> Ecto.Changeset.validate_length({:sections, index, :content}, min: 1)
        end)
    end
  end
end
