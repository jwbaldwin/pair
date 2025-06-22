defmodule Pair.Repo.Migrations.AddCategoryAndIconToMeetingTemplates do
  use Ecto.Migration

  def change do
    alter table(:meeting_templates) do
      add :category, :string
      add :icon, :string
    end
  end
end
