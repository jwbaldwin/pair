defmodule PairWeb.RecordingsLive do
  use PairWeb, :live_view

  alias Pair.Recordings
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Pair.PubSub, "recordings:updates")
    end

    {:ok,
     assign(socket,
       recordings: Recordings.list_recordings(),
       selected_recording: nil,
       show_full_transcript: false
     )}
  end

  @impl true
  def handle_event("select-recording", %{"id" => id}, socket) do
    recording = Recordings.get_recording!(id)
    {:noreply, assign(socket, selected_recording: recording, show_full_transcript: false)}
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
  def handle_info({:recording_updated, %{recording_id: _id}}, socket) do
    recordings = Recordings.list_recordings()

    {:noreply,
     assign(socket, recordings: recordings, selected_recording: socket.assigns.selected_recording)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-background p-6">
      <h1 class="text-2xl font-bold mb-6">Recordings</h1>

      <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div class="md:col-span-1 bg-white rounded-lg shadow p-4">
          <h2 class="text-xl font-semibold mb-4">Recording List</h2>
          <ul class="divide-y divide-gray-200">
            <%= for recording <- @recordings do %>
              <li
                class={"py-3 flex items-center justify-between cursor-pointer rounded-lg hover:bg-gray-100 #{if @selected_recording && @selected_recording.id == recording.id, do: "bg-gray-50", else: ""}"}
                phx-click="select-recording"
                phx-value-id={recording.id}
              >
                <div class="flex items-center">
                  <div class="ml-3">
                    <p class="text-sm font-medium">{extract_filename(recording.upload_url)}</p>
                    <p class="text-xs text-gray-500">{format_date(recording.inserted_at)}</p>
                    <span class={"inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{status_color(recording.status)}"}>
                      {recording.status}
                    </span>
                  </div>
                </div>
              </li>
            <% end %>
          </ul>
        </div>

        <div class="md:col-span-3 bg-white rounded-lg shadow p-4">
          <%= if @selected_recording do %>
            <h2 class="text-xl font-semibold mb-4">Recording Details</h2>
            <div class="mb-6">
              <h3 class="text-lg font-medium mb-2">Transcript</h3>
              <div class="bg-gray-50 p-4 rounded-lg">
                <%= if @selected_recording.transcription do %>
                  <%= if @show_full_transcript do %>
                    <p class="whitespace-pre-wrap">{@selected_recording.transcription}</p>
                    <button
                      class="text-blue-500 hover:text-blue-700 mt-2"
                      phx-click="hide-full-transcript"
                    >
                      Show less
                    </button>
                  <% else %>
                    <p class="whitespace-pre-wrap">
                      {truncate_text(@selected_recording.transcription, 500)}
                    </p>
                    <%= if String.length(@selected_recording.transcription) > 500 do %>
                      <button
                        class="text-blue-500 hover:text-blue-700 mt-2"
                        phx-click="show-full-transcript"
                      >
                        Show full transcript
                      </button>
                    <% end %>
                  <% end %>
                <% else %>
                  <p class="text-gray-500 italic">No transcript available</p>
                <% end %>
              </div>
            </div>

            <div>
              <h3 class="text-lg font-medium mb-2">Generated Actions</h3>
              <div class="bg-gray-50 p-4 rounded-lg">
                <%= if @selected_recording.actions do %>
                  <pre class="whitespace-pre-wrap text-sm"><%= format_actions(@selected_recording.actions) %></pre>
                <% else %>
                  <p class="text-gray-500 italic">No actions available</p>
                <% end %>
              </div>
            </div>
          <% else %>
            <div class="flex items-center justify-center h-full">
              <p class="text-gray-500">Select a recording to view details</p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp extract_filename(nil), do: "Unknown file"

  defp extract_filename(url) do
    url |> String.split("/") |> List.last()
  end

  defp format_date(nil), do: ""

  defp format_date(datetime) do
    datetime
    # For now, just hard-code to EST
    |> Calendar.strftime("%B %d, %Y at %I:%M %p")
  end

  defp truncate_text(nil, _), do: ""

  defp truncate_text(text, max_length) when byte_size(text) > max_length do
    String.slice(text, 0, max_length) <> "..."
  end

  defp truncate_text(text, _), do: text

  defp format_actions(nil), do: ""

  defp format_actions(actions) when is_binary(actions) do
    case Jason.decode(actions) do
      {:ok, decoded} -> Jason.encode!(decoded, pretty: true)
      _ -> actions
    end
  rescue
    _ -> "Unable to format actions"
  end

  defp status_color(:uploaded), do: "bg-gray-100 text-gray-800"
  defp status_color(:transcribed), do: "bg-blue-100 text-blue-800"
  defp status_color(:analyzed), do: "bg-emerald-100 text-emerald-800"
  defp status_color(:error), do: "bg-red-100 text-red-800"
  defp status_color(:completed), do: "bg-green-100 text-green-800"
end
