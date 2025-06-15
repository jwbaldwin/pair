defmodule PairWeb.Recordings.ChatComponent do
  use PairWeb, :live_component

  alias Pair.Clients.Anthropic

  def mount(socket) do
    {:ok,
     assign(socket,
       full_conversation: [],
       display_messages: [],
       form: to_form(%{"message" => ""})
     )}
  end

  def update(%{action: :stream_chunk, chunk: chunk}, socket) do
    [head | rest] = Enum.reverse(socket.assigns.full_conversation)
    updated_message = %{head | content: head.content <> chunk}
    updated_full_conversation = Enum.reverse([updated_message | rest])

    [_ | display_rest] = Enum.reverse(socket.assigns.display_messages)
    updated_display_messages = Enum.reverse([updated_message | display_rest])

    {:ok,
     socket
     |> assign(:full_conversation, updated_full_conversation)
     |> assign(:display_messages, updated_display_messages)}
  end

  def update(%{action: :stream_start}, socket) do
    start_message = %{role: :assistant, content: ""}

    {:ok,
     socket
     |> assign(:full_conversation, socket.assigns.full_conversation ++ [start_message])
     |> assign(:display_messages, socket.assigns.display_messages ++ [start_message])}
  end

  def update(%{action: :stream_complete}, socket) do
    {:ok, socket}
  end

  # Regular assigns updates
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("change", %{"message" => message}, socket) do
    {:noreply, assign(socket, form: to_form(%{"message" => message}))}
  end

  def handle_event("send", %{"message" => message}, socket) when message != "" do
    recording = socket.assigns.recording

    user_question = %{role: :user, content: message}

    messages =
      if Enum.empty?(socket.assigns.full_conversation) do
        context_message = %{
          role: :user,
          content: """
          ## Transcript
          #{recording.transcription}

          ## Meeting Notes
          #{Jason.encode!(recording.meeting_notes)}

          ## Action Items & Insights
          #{recording.actions}
          """
        }

        [context_message, user_question]
      else
        socket.assigns.full_conversation ++ [user_question]
      end

    display_messages = socket.assigns.display_messages ++ [user_question]

    pid = self()

    Task.start(fn ->
      Anthropic.stream_response(pid, messages)
    end)

    {:noreply,
     socket
     |> assign(:full_conversation, messages)
     |> assign(:display_messages, display_messages)
     |> assign(:form, to_form(%{"message" => ""}))}
  end

  def handle_event("send", _, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <div>
      <h3 class="text-sm font-medium text-stone-500 uppercase mb-4">
        ASK pAIr
      </h3>
      <%= for message <- @display_messages do %>
        <%= if message.role == :assistant do %>
          <div class="flex items-start gap-3">
            <div class="w-10 h-10 bg-white border-2 border-green-500 rounded-full flex items-center justify-center text-stone-800 text-sm shrink-0">
              Pair
            </div>
            <div class="bg-white rounded-lg p-3 text-sm space-y-2 border border-stone-100/50 shadow-sm">
              {message.content}
            </div>
          </div>
        <% else %>
          <%= unless Map.get(message, :is_context, false) do %>
            <div class="mb-4">
              <div class="flex items-start gap-3">
                <div class="w-10 h-10 bg-white border-2 border-stone-200 rounded-full flex items-center justify-center text-stone-800 text-sm shrink-0">
                  Me
                </div>
                <div class="bg-stone-200 rounded-lg p-3 text-sm border border-stone-300/50 shadow-sm">
                  {message.content}
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      <% end %>
      
    <!-- Input for new questions -->
      <div class="absolute bottom-5 left-4 right-4">
        <.form for={@form} phx-submit="send" phx-change="change" phx-target={@myself} class="w-full">
          <div class="relative shadow border border-stone-100/50 rounded-md bg-white">
            <input
              name={@form[:message].name}
              value={@form[:message].value}
              phx-debounce="200"
              phx-target={@myself}
              type="text"
              autocomplete="off"
              placeholder="Ask about the meeting..."
              class="px-3 py-3 text-sm w-full border-0 rounded-lg focus:outline-none focus:ring-0 pr-12"
            />
            <button
              type="submit"
              class="absolute right-2 top-1/2 transform -translate-y-1/2 p-1 text-stone-400 hover:bg-stone-100 hover:text-stone-500  rounded transition-colors"
            >
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <g clip-path="url(#clip0_1721_5789)">
                  <path
                    d="M11 12H8.78814C8.13568 12 7.80944 12 7.51559 12.0928C7.25552 12.1748 7.01499 12.3092 6.80878 12.4877C6.57577 12.6894 6.40479 12.9672 6.06284 13.5229L4.8822 15.4414C3.12611 18.2951 2.24806 19.7219 2.42974 20.5187C2.58655 21.2065 3.09409 21.7608 3.76542 21.9774C4.54316 22.2284 6.04163 21.4792 9.03858 19.9807L19.2757 14.8622C21.1181 13.941 22.0393 13.4803 22.3349 12.857C22.5922 12.3146 22.5922 11.6854 22.3349 11.143C22.0393 10.5197 21.1181 10.059 19.2757 9.13784L9.03859 4.0193C6.04164 2.52082 4.54316 1.77158 3.76542 2.02258C3.09409 2.23924 2.58655 2.79354 2.42974 3.48131C2.24806 4.2781 3.12611 5.70493 4.8822 8.55858L5.15385 9L5.5 9.5625"
                    stroke="currentColor"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  />
                </g>
                <defs>
                  <clipPath id="clip0_1721_5789">
                    <rect width="24" height="24" fill="white" />
                  </clipPath>
                </defs>
              </svg>
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
