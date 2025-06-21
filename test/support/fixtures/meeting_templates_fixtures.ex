defmodule Pair.MeetingTemplatesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Pair.MeetingTemplates` context.
  """

  @doc """
  Generate a meeting_template.
  """
  def meeting_template_fixture(attrs \\ %{}) do
    {:ok, meeting_template} =
      attrs
      |> Enum.into(%{
        name: "Test Meeting Template",
        description: "A template for testing purposes",
        sections: ["Overview", "Key Points", "Next Steps"],
        is_system_template: false
      })
      |> Pair.MeetingTemplates.create_meeting_template()

    meeting_template
  end
end