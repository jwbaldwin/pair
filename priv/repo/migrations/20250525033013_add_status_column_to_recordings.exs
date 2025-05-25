defmodule Pair.Repo.Migrations.AddStatusColumnToRecordings do
  use Ecto.Migration

  def change do
    alter table(:recordings) do
      add :status, :string, null: true
    end
  end
end
