defmodule PairWeb.Templates.IndexTest do
  use PairWeb.ConnCase

  import Phoenix.LiveViewTest
  import Pair.MeetingTemplatesFixtures

  @create_attrs %{
    name: "Test Template",
    description: "A test template for testing purposes",
    sections: ["Section 1", "Section 2"]
  }
  @update_attrs %{
    name: "Updated Template",
    description: "An updated test template",
    sections: ["Updated Section 1", "Updated Section 2"]
  }
  @invalid_attrs %{name: nil, description: nil, sections: []}

  defp create_meeting_template(_) do
    meeting_template = meeting_template_fixture()
    %{meeting_template: meeting_template}
  end

  describe "Index" do
    setup [:create_meeting_template]

    test "lists all meeting_templates", %{conn: conn, meeting_template: meeting_template} do
      {:ok, _index_live, html} = live(conn, ~p"/templates")

      assert html =~ "Meeting Templates"
      assert html =~ meeting_template.name
    end

    test "saves new meeting_template", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/templates")

      assert index_live |> element("button", "New Template") |> render_click() =~
               "New Template"

      assert index_live
             |> form("form", meeting_template: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("form", meeting_template: Map.put(@create_attrs, "sections_text", "Section 1\nSection 2"))
             |> render_submit()

      html = render(index_live)
      assert html =~ "Test Template"
    end

    test "updates meeting_template in listing", %{conn: conn, meeting_template: meeting_template} do
      {:ok, index_live, _html} = live(conn, ~p"/templates")

      assert index_live |> element("button", "Edit") |> render_click() =~
               "Edit Template"

      assert index_live
             |> form("form", meeting_template: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("form", meeting_template: Map.put(@update_attrs, "sections_text", "Updated Section 1\nUpdated Section 2"))
             |> render_submit()

      html = render(index_live)
      assert html =~ "Updated Template"
    end

    test "deletes meeting_template in listing", %{conn: conn, meeting_template: meeting_template} do
      {:ok, index_live, _html} = live(conn, ~p"/templates")

      assert index_live |> element("button", "Delete") |> render_click()
      refute has_element?(index_live, "#meeting_template-#{meeting_template.id}")
    end
  end
end