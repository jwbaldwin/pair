defmodule PairWeb.Templates.Index do
  use PairWeb, :live_view

  alias Pair.MeetingTemplates
  alias Pair.MeetingTemplates.MeetingTemplate

  @impl true
  def mount(_params, _session, socket) do
    templates = MeetingTemplates.list_meeting_templates()
    grouped_templates = group_templates_by_category(templates)

    {:ok,
     assign(socket,
       templates: templates,
       grouped_templates: grouped_templates,
       show_form: false,
       form: to_form(MeetingTemplates.change_meeting_template(%MeetingTemplate{})),
       editing_template: nil
     )}
  end

  @impl true
  def handle_event("new_template", _params, socket) do
    {:noreply,
     assign(socket,
       show_form: true,
       editing_template: nil,
       form: to_form(MeetingTemplates.change_meeting_template(%MeetingTemplate{}))
     )}
  end

  @impl true
  def handle_event("edit_template", %{"id" => id}, socket) do
    template = MeetingTemplates.get_meeting_template!(id)

    {:noreply,
     assign(socket,
       show_form: true,
       editing_template: template,
       form: to_form(MeetingTemplates.change_meeting_template(template))
     )}
  end

  @impl true
  def handle_event("cancel_form", _params, socket) do
    {:noreply, assign(socket, show_form: false, editing_template: nil)}
  end

  @impl true
  def handle_event("delete_template", %{"id" => id}, socket) do
    template = MeetingTemplates.get_meeting_template!(id)
    {:ok, _} = MeetingTemplates.delete_meeting_template(template)

    templates = MeetingTemplates.list_meeting_templates()

    {:noreply,
     assign(socket,
       templates: templates,
       grouped_templates: group_templates_by_category(templates)
     )}
  end

  @impl true
  def handle_event("save_template", %{"meeting_template" => params}, socket) do
    # Parse sections from textarea (one per line)
    sections =
      params
      |> Map.get("sections_text", "")
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    template_params = Map.put(params, "sections", sections)

    case socket.assigns.editing_template do
      nil ->
        case MeetingTemplates.create_meeting_template(template_params) do
          {:ok, _template} ->
            templates = MeetingTemplates.list_meeting_templates()

            {:noreply,
             assign(socket,
               templates: templates,
               grouped_templates: group_templates_by_category(templates),
               show_form: false,
               form: to_form(MeetingTemplates.change_meeting_template(%MeetingTemplate{}))
             )}

          {:error, changeset} ->
            {:noreply, assign(socket, form: to_form(changeset))}
        end

      editing_template ->
        case MeetingTemplates.update_meeting_template(editing_template, template_params) do
          {:ok, _template} ->
            templates = MeetingTemplates.list_meeting_templates()

            {:noreply,
             assign(socket,
               templates: templates,
               grouped_templates: group_templates_by_category(templates),
               show_form: false,
               editing_template: nil,
               form: to_form(MeetingTemplates.change_meeting_template(%MeetingTemplate{}))
             )}

          {:error, changeset} ->
            {:noreply, assign(socket, form: to_form(changeset))}
        end
    end
  end

  defp group_templates_by_category(templates) do
    templates
    |> Enum.group_by(fn template ->
      template.category || "Uncategorized"
    end)
    |> Enum.sort_by(fn {category, _} -> category end)
  end

  defp get_template_icon(template) do
    template.icon || default_icon_for_category(template.category)
  end

  defp default_icon_for_category(nil), do: "document-text"
  defp default_icon_for_category("Commercial"), do: "currency-dollar"
  defp default_icon_for_category("Leadership"), do: "user-group"
  defp default_icon_for_category("Product"), do: "cube"
  defp default_icon_for_category(_), do: "document-text"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-white">
      <div class="flex-1 overflow-y-auto px-4 py-12">
        <div class="max-w-4xl mx-auto">
          <!-- Header -->
          <div class="flex justify-between items-center mb-8">
            <div>
              <div class="flex items-center space-x-3 mb-2">
                <.back navigate={~p"/"}>Back</.back>
              </div>
              <h1 class="text-xl font-semibold text-stone-800">My templates</h1>
              <p class="text-stone-600 mt-1">
                Create custom templates for different types of meetings
              </p>
            </div>
            <.button phx-click="new_template">
              Create template
            </.button>
          </div>
          
    <!-- Form Modal -->
          <%= if @show_form do %>
            <div class="fixed inset-0 bg-stone-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
              <div class="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white">
                <div class="mt-3">
                  <h3 class="text-lg font-medium text-stone-900 mb-4">
                    {if @editing_template, do: "Edit Template", else: "New Template"}
                  </h3>

                  <.form for={@form} phx-submit="save_template" class="space-y-4">
                    <div>
                      <.input
                        field={@form[:name]}
                        label="Template Name"
                        placeholder="e.g., Client Discovery Call"
                      />
                    </div>

                    <div>
                      <.input
                        field={@form[:description]}
                        type="textarea"
                        label="Description"
                        placeholder="Describe the purpose and context of this meeting type..."
                        rows="3"
                      />
                    </div>

                    <div class="grid grid-cols-2 gap-4">
                      <div>
                        <.input
                          field={@form[:category]}
                          type="select"
                          label="Category"
                          options={[
                            {"Commercial", "Commercial"},
                            {"Leadership", "Leadership"},
                            {"Product", "Product"},
                            {"Other", "Other"}
                          ]}
                          prompt="Select category"
                        />
                      </div>
                      <div>
                        <.input
                          field={@form[:icon]}
                          label="Icon (optional)"
                          placeholder="e.g., currency-dollar, user-group"
                        />
                      </div>
                    </div>

                    <div>
                      <label class="block text-sm font-medium text-stone-700 mb-2">
                        Sections (one per line)
                      </label>
                      <textarea
                        name="meeting_template[sections_text]"
                        rows="6"
                        class="mt-1 block w-full rounded-md border-stone-300 shadow-sm focus:border-sky-500 focus:ring-sky-500 sm:text-sm"
                        placeholder={
                          ~s(About the client\nProject requirements\nTimeline & budget\nNext steps)
                        }
                      ><%= if @editing_template, do: Enum.join(@editing_template.sections, "\n"), else: "" %></textarea>
                    </div>

                    <div class="flex justify-end space-x-3 pt-4">
                      <.button type="button" phx-click="cancel_form">Cancel</.button>
                      <.button type="submit" primary>
                        {if @editing_template, do: "Update Template", else: "Create Template"}
                      </.button>
                    </div>
                  </.form>
                </div>
              </div>
            </div>
          <% end %>
          
    <!-- Templates List -->
          <div class="space-y-8">
            <%= for {category, templates} <- @grouped_templates do %>
              <div>
                <h2 class="text-lg font-semibold text-stone-900 mb-4">{category}</h2>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  <%= for template <- templates do %>
                    <div class="bg-white border border-stone-200 rounded-lg p-6 hover:shadow-md transition-shadow cursor-pointer group relative">
                      <div class="flex items-start justify-between mb-4">
                        <div class="flex items-center space-x-3">
                          <div class="w-10 h-10 bg-blue-50 rounded-lg flex items-center justify-center">
                            <.icon name={get_template_icon(template)} class="w-5 h-5 text-blue-600" />
                          </div>
                          <div>
                            <h3 class="font-medium text-stone-900 text-sm">{template.name}</h3>
                            <%= if template.is_system_template do %>
                              <span class="inline-flex items-center text-xs text-stone-500 mt-1">
                                <.icon name="eye" class="w-3 h-3 mr-1" /> View only
                              </span>
                            <% end %>
                          </div>
                        </div>
                        <div class="opacity-0 group-hover:opacity-100 transition-opacity flex space-x-1">
                          <button
                            phx-click="edit_template"
                            phx-value-id={template.id}
                            class="p-1 text-stone-400 hover:text-stone-600 rounded"
                          >
                            <.icon name="pencil" class="w-4 h-4" />
                          </button>
                          <%= unless template.is_system_template do %>
                            <button
                              phx-click="delete_template"
                              phx-value-id={template.id}
                              data-confirm="Are you sure you want to delete this template?"
                              class="p-1 text-stone-400 hover:text-red-600 rounded"
                            >
                              <.icon name="trash" class="w-4 h-4" />
                            </button>
                          <% end %>
                        </div>
                      </div>

                      <div class="mb-4">
                        <h4 class="text-xs font-medium text-stone-900 mb-2">Meeting Context</h4>
                        <p class="text-xs text-stone-600 leading-relaxed">{template.description}</p>
                      </div>

                      <div class="mb-4">
                        <h4 class="text-xs font-medium text-stone-900 mb-2">Sections</h4>
                        <div class="space-y-1">
                          <%= for section <- Enum.take(template.sections, 4) do %>
                            <div class="text-xs text-stone-600">{section}</div>
                          <% end %>
                          <%= if length(template.sections) > 4 do %>
                            <div class="text-xs text-stone-400">
                              +{length(template.sections) - 4} more...
                            </div>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>

            <%= if Enum.empty?(@templates) do %>
              <div class="text-center py-12">
                <div class="mx-auto h-12 w-12 text-stone-400">
                  <svg fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                    />
                  </svg>
                </div>
                <h3 class="mt-2 text-sm font-medium text-stone-900">No templates</h3>
                <p class="mt-1 text-sm text-stone-500">
                  Get started by creating your first meeting template.
                </p>
                <div class="mt-6">
                  <.button
                    phx-click="new_template"
                    class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-sky-600 hover:bg-sky-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-sky-500"
                  >
                    Create template
                  </.button>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
