defmodule PairWeb.Recordings.Show do
  use PairWeb, :live_view

  import PairWeb.Helpers

  alias Pair.Recordings
  alias Phoenix.PubSub

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok, recording} = Recordings.fetch_recording_with_meeting_notes(id)

    if connected?(socket) do
      PubSub.subscribe(Pair.PubSub, "recordings:updates")
    end

    {:ok,
     assign(socket,
       recording: recording,
       show_full_transcript: false,
       active_tab: "meeting_notes"
     )}
  end

  @impl true
  def handle_event("show-full-transcript", _, socket) do
    {:noreply, assign(socket, show_full_transcript: true)}
  end

  @impl true
  def handle_event("hide-full-transcript", _, socket) do
    {:noreply, assign(socket, show_full_transcript: false)}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  @impl true
  def handle_info({:recording_updated, %{recording_id: id}}, socket) do
    if socket.assigns.recording.id == id do
      {:ok, recording} = Recordings.fetch_recording_with_meeting_notes(id)

      {:noreply, assign(socket, recording: recording)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:stream_chunk, chunk}, socket) do
    send_update(PairWeb.Recordings.ChatComponent,
      id: "chat-component",
      action: :stream_chunk,
      chunk: chunk
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:stream_start}, socket) do
    send_update(PairWeb.Recordings.ChatComponent,
      id: "chat-component",
      action: :stream_start
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:stream_complete}, socket) do
    send_update(PairWeb.Recordings.ChatComponent,
      id: "chat-component",
      action: :stream_complete
    )

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-6xl mx-auto space-y-4">
      <div class="flex h-screen">
        <!-- Main Content Area -->
        <div class="flex-1 p-8 overflow-y-auto">
          <!-- Header -->
          <.link
            navigate={~p"/"}
            class="inline-flex items-center gap-2 text-sm font-medium text-stone-600 hover:text-stone-900 transition-colors"
          >
            <svg
              width="16"
              height="16"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="h-4 w-4"
            >
              <path d="m12 19-7-7 7-7" />
              <path d="M19 12H5" />
            </svg>
            Back
          </.link>
          <div class="mb-8">
            <h1 class="text-2xl font-bold text-stone-800">
              {get_meeting_title(@recording)}
            </h1>
            
    <!-- Meeting Metadata -->
            <% metadata = Map.get(@recording.meeting_notes, "meeting_metadata") %>
            <%= if metadata && Map.get(metadata, "meeting_type") do %>
              <div class="mb-2 text-sm text-stone-700">
                <span class="text-stone-500">
                  {Map.get(metadata, "meeting_type")}
                </span>
              </div>
            <% end %>
            
    <!-- Meeting Info -->
            <div class="flex items-center gap-6 text-sm text-stone-800 mb-6">
              <div class="flex items-center gap-2 bg-stone-100 border border-stone-200/75 shadow-xs rounded-md px-2 py-1">
                <.icon name="calendar" class="w-4 h-4" />
                <span>{format_time(@recording.inserted_at)}</span>
              </div>
              <div class="flex items-center gap-2">
                <!-- Participants Section -->
                <%= if Map.get(@recording.meeting_notes, "participants") && length(Map.get(@recording.meeting_notes, "participants", [])) > 0 do %>
                  <div class="group flex items-center">
                    <%= for {participant, index} <- Enum.with_index(Map.get(@recording.meeting_notes, "participants", [])) do %>
                      <div class={[
                        "flex items-center gap-2 bg-stone-100 border border-stone-200/75 shadow-xs rounded-md px-2 py-1 transition-all duration-300 ease-out",
                        index > 0 && "-ml-5 group-hover:ml-3"
                      ]}>
                        <div class="w-5 h-5 bg-green-500 rounded-full flex items-center justify-center text-white text-xs">
                          {get_initials(Map.get(participant, "name", ""))}
                        </div>
                        <div class={[
                          "transition-all duration-300 ease-out overflow-hidden",
                          index < length(Map.get(@recording.meeting_notes, "participants", [])) - 1 &&
                            "w-0 opacity-0 group-hover:w-auto group-hover:opacity-100"
                        ]}>
                          <div class="text-sm text-stone-800 whitespace-nowrap">
                            {Map.get(participant, "name", "Client")}
                            <%= if Map.get(participant, "role") do %>
                              <span class="text-xs text-stone-500">
                                - {Map.get(participant, "role")}
                              </span>
                            <% end %>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
            
    <!-- Tab Toggle -->
            <div class="relative flex bg-stone-100 rounded-md p-1 mb-8 w-48 inset-shadow-sm">
              <!-- sliding background -->
              <div class={[
                "absolute inset-1 w-[calc(50%-0.25rem)] bg-white rounded-md shadow-sm transition-transform duration-300 ease-out",
                @active_tab == "transcript" && "translate-x-full"
              ]} />
              <button
                phx-click="switch_tab"
                phx-value-tab="meeting_notes"
                class={[
                  "relative z-10 px-3 py-1.5 basis-1/2 text-sm rounded-md shrink-0",
                  @active_tab == "meeting_notes" && "text-stone-900",
                  @active_tab != "meeting_notes" && "text-stone-600 hover:text-stone-900"
                ]}
              >
                Notes
              </button>

              <button
                phx-click="switch_tab"
                phx-value-tab="transcript"
                class={[
                  "relative z-10 px-3 py-1.5 basis-1/2 text-sm rounded-md shrink-0",
                  @active_tab == "transcript" && "text-stone-900",
                  @active_tab != "transcript" && "text-stone-600 hover:text-stone-900"
                ]}
              >
                Transcript
              </button>
            </div>
          </div>
          
    <!-- Content based on active tab -->
          <div class="space-y-8">
            <%= if @active_tab == "meeting_notes" do %>
              <.render_meeting_notes meeting_notes={@recording.meeting_notes} />
            <% else %>
              <.render_transcript actions={@recording.transcription} />
            <% end %>
          </div>
        </div>
        
    <!-- Right Sidebar -->
        <div class="relative w-80 bg-stone-100 border-l border-stone-200 p-6 space-y-8">
          <!-- Share Notes Section -->
          <div>
            <div class="flex gap-3">
              <button class="flex items-center bg-white justify-center gap-2 px-2 py-2 border border-stone-200/75 shadow-xs rounded-md hover:border-stone-200 text-sm">
                <.icon name="link" class="w-4 h-4" /> Copy link
              </button>
              <button class="flex items-center bg-white justify-center gap-2 px-2 py-2 border border-stone-200/75 shadow-xs rounded-md hover:border-stone-200 text-sm">
                <.icon name="email" class="w-4 h-4" /> Email
              </button>
            </div>
          </div>
          <.live_component
            module={PairWeb.Recordings.ChatComponent}
            id="chat-component"
            recording={@recording}
          />
        </div>
      </div>
    </div>
    """
  end

  # Component for rendering meeting notes
  defp render_meeting_notes(assigns) do
    ~H"""
    <%= if @meeting_notes && @meeting_notes != %{} do %>
      <!-- Content Sections -->
      <%= if Map.get(@meeting_notes, "sections") do %>
        <%= for section <- Map.get(@meeting_notes, "sections", []) do %>
          <div class="mb-8">
            <h2 class="text-xl font-semibold text-stone-900 mb-4 flex items-center">
              <span class="text-stone-400 mr-2">#</span>
              {Map.get(section, "title", "Untitled Section")}
              <%= if Map.get(section, "type") do %>
                <span class="ml-2 px-2 py-1 text-xs font-medium bg-stone-100 text-stone-600 rounded-md uppercase">
                  {format_section_type(Map.get(section, "type"))}
                </span>
              <% end %>
            </h2>
            <%= if Map.get(section, "content") && length(Map.get(section, "content", [])) > 0 do %>
              <ul class="space-y-2">
                <%= for {item, index} <- Enum.with_index(Map.get(section, "content", [])) do %>
                  <li class="flex items-start">
                    <span class={[
                      "w-2 h-2 rounded-full mt-2 mr-3 shrink-0",
                      get_bullet_color(Map.get(section, "type"), index)
                    ]}>
                    </span>
                    <span class="text-stone-700">{item}</span>
                  </li>
                <% end %>
              </ul>
            <% else %>
              <p class="text-stone-500 italic">No content available for this section.</p>
            <% end %>
          </div>
        <% end %>
      <% else %>
        <div class="text-center py-12">
          <div class="text-stone-400 mb-4">
            <svg class="w-12 h-12 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
              >
              </path>
            </svg>
          </div>
          <h3 class="text-lg font-medium text-stone-900 mb-2">No meeting notes available</h3>
          <p class="text-stone-500">
            Meeting notes are still being processed or haven't been generated yet.
          </p>
        </div>
      <% end %>
    <% else %>
      <div class="text-center py-12">
        <div class="text-stone-400 mb-4">
          <svg class="w-12 h-12 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
            >
            </path>
          </svg>
        </div>
        <h3 class="text-lg font-medium text-stone-900 mb-2">No meeting notes available</h3>
        <p class="text-stone-500">
          Meeting notes are still being processed or haven't been generated yet.
        </p>
      </div>
    <% end %>
    """
  end

  # Component for rendering transcript (legacy actions)
  defp render_transcript(assigns) do
    ~H"""
    <%= if @actions && @actions != "" do %>
      <div class="bg-stone-50 rounded-md p-6">
        <h2 class="text-xl font-semibold text-stone-900 mb-4 flex items-center">
          <span class="text-stone-400 mr-2">#</span> Transcript
        </h2>
        <div class="bg-white rounded-md p-4 border border-stone-200">
          <pre class="text-sm text-stone-700 whitespace-pre-wrap font-mono">{format_actions(@actions)}</pre>
        </div>
      </div>
    <% else %>
      <div class="text-center py-12">
        <div class="text-stone-400 mb-4">
          <svg class="w-12 h-12 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            >
            </path>
          </svg>
        </div>
        <h3 class="text-lg font-medium text-stone-900 mb-2">No transcript available</h3>
        <p class="text-stone-500">
          AI insights are still being processed or haven't been generated yet.
        </p>
      </div>
    <% end %>
    """
  end

  # Helper functions
  defp get_meeting_title(recording) do
    case recording.meeting_notes do
      %{"meeting_metadata" => %{"primary_topic" => topic}} when topic != nil and topic != "" ->
        topic

      _ ->
        "Meeting Notes"
    end
  end

  defp get_initials(name) when is_binary(name) do
    name
    |> String.split()
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp get_initials(_), do: "?"

  defp format_section_type(type) when is_binary(type), do: String.replace(type, "_", " ")
  defp format_section_type(_), do: ""

  defp get_bullet_color(section_type, index) do
    case section_type do
      "action_items" ->
        "bg-red-400"

      "decisions" ->
        "bg-green-400"

      "key_points" ->
        "bg-blue-400"

      "next_steps" ->
        "bg-purple-400"

      "overview" ->
        "bg-stone-400"

      _ ->
        # Alternate colors for other types
        case rem(index, 3) do
          0 -> "bg-stone-400"
          1 -> "bg-stone-300"
          2 -> "bg-stone-200"
        end
    end
  end

  def format_actions(nil), do: ""

  def format_actions(actions) when is_binary(actions) do
    case Jason.decode(actions) do
      {:ok, decoded} -> Jason.encode!(decoded, pretty: true)
      _ -> actions
    end
  rescue
    _ -> "Unable to format actions"
  end
end
