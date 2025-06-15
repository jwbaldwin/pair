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
      <h3 class="text-sm font-medium text-stone-600 tracking-tight uppercase mb-4">
        ASK pAIr
      </h3>
      <%= for message <- @display_messages do %>
        <%= if message.role == :assistant do %>
          <div class="flex items-start gap-3">
            <div class="w-10 h-10 bg-white border-2 border-green-500 rounded-full flex items-center justify-center text-stone-800 text-sm shrink-0">
              Pair
            </div>
            <div class="bg-white rounded-md p-3 text-sm space-y-2 border border-stone-100/50 shadow-sm">
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
                <div class="bg-stone-200 rounded-md p-3 text-sm border border-stone-300/50 shadow-sm">
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
              class="px-3 py-3 text-sm w-full border-0 rounded-md focus:outline-none focus:ring-0 pr-12"
            />
            <button
              type="submit"
              class="absolute right-2 top-1/2 transform -translate-y-1/2 p-1 text-stone-400 hover:bg-stone-100 hover:text-stone-500  rounded transition-colors"
            >
              <.icon name="send" class="h-4 w-4" />
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
