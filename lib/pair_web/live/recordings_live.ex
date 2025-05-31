defmodule PairWeb.RecordingsLive do
  use PairWeb, :live_view

  import PairWeb.Helpers

  alias Pair.Recordings
  alias Phoenix.PubSub

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    recording = Recordings.get_recording!(id)

    if connected?(socket) do
      PubSub.subscribe(Pair.PubSub, "recordings:updates")
    end

    # TODO: idk about this
    meeting_notes =
      case Recordings.fetch_meeting_notes(recording) do
        {:ok, notes} -> notes
        {:error, _} -> nil
      end

    {:ok,
     assign(socket,
       recording: recording,
       meeting_notes: meeting_notes,
       show_full_transcript: false
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
  def handle_info({:recording_updated, %{recording_id: id}}, socket) do
    if socket.assigns.recording.id == id do
      recording = Recordings.get_recording!(id)

      # TODO: idk about this either
      meeting_notes =
        case Recordings.fetch_meeting_notes(recording) do
          {:ok, notes} -> notes
          {:error, _} -> nil
        end

      {:noreply, assign(socket, recording: recording, meeting_notes: meeting_notes)}
    else
      {:noreply, socket}
    end
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
            class="inline-flex items-center gap-2 text-sm font-medium text-gray-600 hover:text-gray-900 transition-colors"
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
            <h1 class="text-3xl font-bold text-gray-900 mb-4">
              {Map.get(@recording, :title, "Meeting Notes")}
            </h1>
            
    <!-- Meeting Info -->
            <div class="flex items-center gap-6 text-sm text-gray-600">
              <div class="flex items-center gap-2">
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z"
                    clip-rule="evenodd"
                  >
                  </path>
                </svg>
                <span>{format_time(@recording.inserted_at)}</span>
              </div>
              <div class="flex items-center gap-2">
                <div class="w-6 h-6 bg-blue-500 rounded-full flex items-center justify-center text-white text-xs font-medium">
                  JB
                </div>
                <span>Me</span>
              </div>
            </div>
          </div>
          
    <!-- Content Sections -->
          <div class="space-y-8">
            <!-- Product Overview Section -->
            <div>
              <h2 class="text-xl font-semibold text-gray-900 mb-4 flex items-center">
                <span class="text-gray-400 mr-2">#</span> Product Overview
              </h2>
              <ul class="space-y-2 text-gray-700">
                <li class="flex items-start">
                  <span class="w-2 h-2 bg-gray-400 rounded-full mt-2 mr-3 flex-shrink-0"></span>
                  Pair AI offers meeting note-taking functionality
                </li>
                <li class="flex items-start text-gray-500">
                  <span class="w-2 h-2 bg-gray-300 rounded-full mt-2 mr-3 flex-shrink-0"></span>
                  Integrates with Google Calendar to show upcoming appointments
                </li>
                <li class="flex items-start text-gray-500">
                  <span class="w-2 h-2 bg-gray-300 rounded-full mt-2 mr-3 flex-shrink-0"></span>
                  Automatically identifies and includes meeting participants
                </li>
              </ul>
            </div>
            
    <!-- Key Features Section -->
            <div>
              <h2 class="text-xl font-semibold text-gray-900 mb-4 flex items-center">
                <span class="text-gray-400 mr-2">#</span> Key Features
              </h2>
              <ul class="space-y-2 text-gray-500">
                <li class="flex items-start">
                  <span class="w-2 h-2 bg-gray-300 rounded-full mt-2 mr-3 flex-shrink-0"></span>
                  Internal microphone recording capability
                </li>
                <li class="flex items-start">
                  <span class="w-2 h-2 bg-gray-300 rounded-full mt-2 mr-3 flex-shrink-0"></span>
                  Automatic date/meeting participant detection
                </li>
                <li class="flex items-start">
                  <span class="w-2 h-2 bg-gray-300 rounded-full mt-2 mr-3 flex-shrink-0"></span>
                  Real-time transcription during meetings
                </li>
                <li class="flex items-start">
                  <span class="w-2 h-2 bg-gray-300 rounded-full mt-2 mr-3 flex-shrink-0"></span>
                  Shows live transcript while recording
                </li>
                <li class="flex items-start">
                  <span class="w-2 h-2 bg-gray-300 rounded-full mt-2 mr-3 flex-shrink-0"></span>
                  Ability to take rough notes alongside transcription
                </li>
              </ul>
            </div>
            
    <!-- Integration Capabilities Section -->
            <div>
              <h2 class="text-xl font-semibold text-gray-900 mb-4 flex items-center">
                <span class="text-gray-400 mr-2">#</span> Integration Capabilities
              </h2>
              <ul class="space-y-2 text-gray-500">
                <li class="flex items-start">
                  <span class="w-2 h-2 bg-gray-300 rounded-full mt-2 mr-3 flex-shrink-0"></span>
                  Google Calendar connection pulls in:
                </li>
              </ul>
            </div>
          </div>
        </div>
        
    <!-- Right Sidebar -->
        <div class="w-80 bg-white border-l border-gray-200 p-6 space-y-8">
          <!-- Share Notes Section -->
          <div>
            <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wide mb-4">
              SHARE NOTES
            </h3>
            <div class="grid grid-cols-2 gap-3">
              <button class="flex items-center justify-center gap-2 px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 text-sm">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"
                  >
                  </path>
                </svg>
                Copy link
              </button>
              <button class="flex items-center justify-center gap-2 px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 text-sm">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  >
                  </path>
                </svg>
                Copy text
              </button>
              <button class="flex items-center justify-center gap-2 px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 text-sm">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M3 8l7.89 4.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                  >
                  </path>
                </svg>
                Email
              </button>
              <button class="flex items-center justify-center gap-2 px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 text-sm">
                <div class="w-4 h-4 bg-gradient-to-br from-purple-500 via-pink-500 to-red-500 rounded">
                </div>
                Slack
              </button>
            </div>
          </div>
          
    <!-- Ask Granola Section -->
          <div>
            <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wide mb-4">
              ASK GRANOLA
            </h3>
            
    <!-- User Question -->
            <div class="mb-4">
              <div class="flex items-start gap-3">
                <div class="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-medium flex-shrink-0">
                  JB
                </div>
                <div class="bg-gray-100 rounded-lg p-3 text-sm">
                  What are the 3-4 next steps from the meeting above that I need to do?
                </div>
              </div>
            </div>
            
    <!-- AI Response -->
            <div class="flex items-start gap-3">
              <div class="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center text-white text-sm font-bold flex-shrink-0">
                gi
              </div>
              <div class="bg-gray-100 rounded-lg p-3 text-sm space-y-2">
                <p><strong>1. Evaluate Tool Finder placement potential for Pair AI.</strong></p>
                <p><strong>2. Review the full feature set of Pair AI.</strong></p>
                <p><strong>3. Make a decision on the coverage approach for Pair AI.</strong></p>
              </div>
            </div>
            
    <!-- Input for new questions -->
            <div class="mt-4">
              <div class="flex gap-2">
                <input
                  type="text"
                  placeholder="Ask a question about this meeting..."
                  class="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <button class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 text-sm">
                  Ask
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
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
