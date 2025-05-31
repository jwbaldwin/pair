defmodule Pair.Recordings.Recording do
  use Pair.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}
  @type id :: UUIDv7.t()
  @type status :: :uploaded | :transcribing | :analyzing | :structuring | :error | :completed

  schema "recordings" do
    field :upload_url, :string
    field :transcription, :string
    field :actions, :string
    field :meeting_notes, :string

    field :status, Ecto.Enum,
      values: [:uploaded, :transcribing, :structuring, :analyzing, :error, :completed]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recording, attrs) do
    recording
    |> cast(attrs, [:upload_url, :transcription, :meeting_notes, :actions, :status])
    |> validate_required([:upload_url])
  end
end
