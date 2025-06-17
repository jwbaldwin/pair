defmodule Pair.Repo.Migrations.CreateMeetingTemplates do
  use Ecto.Migration

  def change do
    create table(:meeting_templates) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :sections, :jsonb, null: false, default: "[]"
      add :is_system_template, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:meeting_templates, [:is_system_template])
  end
end
