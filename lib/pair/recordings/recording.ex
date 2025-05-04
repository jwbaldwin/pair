defmodule Pair.Recordings.Recording do
  use Pair.Schema

  import Ecto.Changeset

  schema "recordings" do
    field :upload_url, :string
    field :transcription, :string
    field :actions, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(recording, attrs) do
    recording
    |> cast(attrs, [:upload_url, :transcription, :actions])
    |> validate_required([:upload_url])
  end
end
