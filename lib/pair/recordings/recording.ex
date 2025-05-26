defmodule Pair.Recordings.Recording do
  use Pair.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}
  @type id :: UUIDv7.t()
  @type status :: :uploaded | :transcribed | :analyzed | :error | :completed

  schema "recordings" do
    field :upload_url, :string
    field :transcription, :string
    field :actions, :string

    field :status, Ecto.Enum, values: [:uploaded, :transcribed, :analyzed, :error, :completed]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recording, attrs) do
    recording
    |> cast(attrs, [:upload_url, :transcription, :actions, :status])
    |> validate_required([:upload_url])
  end
end
