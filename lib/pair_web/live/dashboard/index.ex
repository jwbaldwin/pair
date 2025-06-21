defmodule PairWeb.Dashboard.Index do
  use PairWeb, :live_view

  import PairWeb.Helpers

  alias Pair.Recordings
  alias Phoenix.PubSub
  alias PairWeb.Dashboard.Navbar

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Pair.PubSub, "recordings:updates")
    end

    {:ok,
     assign(socket,
       recordings: Recordings.list_recordings_by_date()
     )}
  end

  @impl true
  def handle_info({:recording_updated, _}, socket) do
    {:noreply, assign(socket, recordings: Recordings.list_recordings_by_date())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-white">
      <div class="flex-1 overflow-y-auto px-4 py-12">
        <div class="max-w-3xl mx-auto space-y-6">
          <Navbar.navbar />
          <div class="w-full rounded-lg">
            <%= for {date_group, recordings} <- @recordings do %>
              <!-- Date Header -->
              <div class="mb-4">
                <h3 class="text-lg font-semibold text-stone-900 mb-3">
                  {format_date_header(date_group)}
                </h3>
                <%= for recording <- recordings do %>
                  <.link
                    class="py-3 px-3 flex items-center cursor-pointer rounded-lg hover:bg-stone-50 transition-colors duration-150"
                    navigate={~p"/recordings/#{recording.id}"}
                  >
                    <!-- File Icon -->
                    <div class="shrink-0 mr-3">
                      <div class="w-8 h-8 bg-stone-100 border border-stone-200/50 shadow-xs rounded-lg flex items-center justify-center">
                        <svg class="w-4 h-4 text-stone-600" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M4 3a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V5a2 2 0 00-2-2H4zm12 12H4l4-8 3 6 2-4 3 6z" />
                        </svg>
                      </div>
                    </div>
                    <!-- Content -->
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-medium text-stone-900 truncate">
                        {extract_filename(recording.upload_url)}
                      </p>
                      <p class="text-xs text-stone-500 mt-0.5">
                        {format_time(recording.inserted_at)}
                      </p>
                    </div>
                    <!-- Status Badge (if needed) -->
                    <%= if recording.status != "completed" do %>
                      <div class="shrink-0 ml-2 text-sm font-medium text-stone-500">
                        <span class="inline-flex items-center h-2 w-2 rounded-full text-xs font-medium bg-yellow-500" />
                        {String.capitalize(Atom.to_string(recording.status))}
                      </div>
                    <% end %>
                  </.link>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
