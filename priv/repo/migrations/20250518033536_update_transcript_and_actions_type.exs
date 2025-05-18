defmodule Pair.Repo.Migrations.UpdateTranscripAndActionsType do
  use Ecto.Migration

  def change do
    alter table(:recordings) do
      modify :actions, :text
      modify :transcription, :text
    end
  end
end
