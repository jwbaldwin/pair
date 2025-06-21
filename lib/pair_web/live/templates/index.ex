defmodule PairWeb.Templates.Index do
  use PairWeb, :live_view

  alias Pair.MeetingTemplates
  alias Pair.MeetingTemplates.MeetingTemplate

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       templates: MeetingTemplates.list_meeting_templates(),
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

    {:noreply, assign(socket, templates: MeetingTemplates.list_meeting_templates())}
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
            {:noreply,
             assign(socket,
               templates: MeetingTemplates.list_meeting_templates(),
               show_form: false,
               form: to_form(MeetingTemplates.change_meeting_template(%MeetingTemplate{}))
             )}

          {:error, changeset} ->
            {:noreply, assign(socket, form: to_form(changeset))}
        end

      editing_template ->
        case MeetingTemplates.update_meeting_template(editing_template, template_params) do
          {:ok, _template} ->
            {:noreply,
             assign(socket,
               templates: MeetingTemplates.list_meeting_templates(),
               show_form: false,
               editing_template: nil,
               form: to_form(MeetingTemplates.change_meeting_template(%MeetingTemplate{}))
             )}

          {:error, changeset} ->
            {:noreply, assign(socket, form: to_form(changeset))}
        end
    end
  end

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
              <h1 class="text-2xl font-bold text-stone-900">Meeting Templates</h1>
              <p class="text-stone-600 mt-1">
                Create and manage templates for different types of meetings
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

                    <div>
                      <label class="block text-sm font-medium text-stone-700 mb-2">
                        Sections (one per line)
                      </label>
                      <textarea
                        name="meeting_template[sections_text]"
                        rows="6"
                        class="mt-1 block w-full rounded-md border-stone-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
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
          <div class="space-y-4">
            <%= for template <- @templates do %>
              <div class="bg-white border border-stone-200 rounded-lg p-6 hover:shadow-md transition-shadow">
                <div class="flex justify-between items-start">
                  <div class="flex-1">
                    <div class="flex items-center space-x-2 mb-2">
                      <h3 class="text-lg font-medium text-stone-900">{template.name}</h3>
                      <%= if template.is_system_template do %>
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                          System
                        </span>
                      <% end %>
                    </div>
                    <p class="text-stone-600 mb-3">{template.description}</p>
                    <div class="flex flex-wrap gap-2">
                      <%= for section <- template.sections do %>
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-stone-100 text-stone-800">
                          {section}
                        </span>
                      <% end %>
                    </div>
                  </div>
                  <div class="flex space-x-2 ml-4">
                    <button
                      phx-click="edit_template"
                      phx-value-id={template.id}
                      class="text-blue-600 hover:text-blue-900 text-sm font-medium"
                    >
                      Edit
                    </button>
                    <%= unless template.is_system_template do %>
                      <button
                        phx-click="delete_template"
                        phx-value-id={template.id}
                        data-confirm="Are you sure you want to delete this template?"
                        class="text-red-600 hover:text-red-900 text-sm font-medium"
                      >
                        Delete
                      </button>
                    <% end %>
                  </div>
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
                  <button
                    phx-click="new_template"
                    class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                  >
                    New Template
                  </button>
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
