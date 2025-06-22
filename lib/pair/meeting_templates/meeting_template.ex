defmodule Pair.MeetingTemplates.MeetingTemplate do
  use Pair.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}
  @type id :: UUIDv7.t()

  schema "meeting_templates" do
    field :name, :string
    field :description, :string
    field :sections, {:array, :string}
    field :is_system_template, :boolean, default: false
    field :category, :string
    field :icon, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meeting_template, attrs) do
    meeting_template
    |> cast(attrs, [:name, :description, :sections, :is_system_template, :category, :icon])
    |> validate_required([:name, :description, :sections])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:description, min: 1)
    |> validate_sections()
  end

  defp validate_sections(changeset) do
    case get_field(changeset, :sections) do
      nil ->
        add_error(changeset, :sections, "must have at least one section")

      [] ->
        add_error(changeset, :sections, "must have at least one section")

      sections ->
        validate_section_names(changeset, sections)
    end
  end

  defp validate_section_names(changeset, sections) do
    sections
    |> Enum.with_index()
    |> Enum.reduce(changeset, fn {section, index}, acc ->
      cond do
        not is_binary(section) ->
          add_error(acc, :sections, "section #{index + 1} must be a string")

        String.trim(section) == "" ->
          add_error(acc, :sections, "section #{index + 1} cannot be empty")

        true ->
          acc
      end
    end)
  end
end
