defmodule Pair.Repo.Migrations.CreateRecordings do
  use Ecto.Migration

  def change do
    create table(:recordings) do
      add :upload_url, :string
      add :transcription, :string
      add :actions, :string

      timestamps(type: :utc_datetime)
    end
  end
end
