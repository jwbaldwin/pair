defmodule Pair.Repo.Migrations.AddMeetingNotesToRecordings do
  use Ecto.Migration

  def change do
    alter table(:recordings) do
      add :meeting_notes, :text
    end
  end
end
