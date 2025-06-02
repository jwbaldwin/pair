defmodule PairWeb.Recordings.ChatComponent do
  use PairWeb, :live_component

  alias Pair.Clients.Anthropic

  def mount(socket) do
    {:ok,
     assign(socket,
       messages: [],
       form: to_form(%{"message" => ""})
     )}
  end

  def update(%{action: :stream_chunk, chunk: chunk}, socket) do
    [head | rest] = Enum.reverse(socket.assigns.messages)
    updated_message = %{head | content: head.content <> chunk}
    updated_messages = Enum.reverse([updated_message | rest])

    {:ok, assign(socket, :messages, updated_messages)}
  end

  def update(%{action: :stream_start}, socket) do
    {:ok,
     assign(socket, :messages, socket.assigns.messages ++ [%{role: :assistant, content: ""}])}
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
    messages = socket.assigns.messages ++ [%{role: :user, content: message}]

    pid = self()
    Task.start(fn ->
      Anthropic.stream_response(pid, messages)
    end)

    {:noreply,
     socket
     |> assign(:messages, messages)
     |> assign(:form, to_form(%{"message" => ""}))}
  end

  def handle_event("send", _, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <div>
      <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wide mb-4">
        ASK pAIr
      </h3>
      
    <!-- User Question -->
      
    <!-- AI Response -->

      <%= for message <- @messages do %>
        <%= if message.role == :assistant do %>
          <div class="flex items-start gap-3">
            <div class="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center text-white text-sm font-bold shrink-0">
              Pair
            </div>
            <div class="bg-gray-100 rounded-lg p-3 text-sm space-y-2">{message.content}</div>
          </div>
        <% else %>
          <div class="mb-4">
            <div class="flex items-start gap-3">
              <div class="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-medium shrink-0">
                Me
              </div>
              <div class="bg-gray-100 rounded-lg p-3 text-sm">{message.content}</div>
            </div>
          </div>
        <% end %>
      <% end %>
      
    <!-- Input for new questions -->
      <div class="mt-4">
        <div class="flex gap-2">
          <.form
            for={@form}
            phx-submit="send"
            phx-change="change"
            phx-target={@myself}
            class="flex gap-2 items-center"
          >
            <div class="flex-1 relative">
              <.input
                field={@form[:message]}
                phx-debounce="200"
                phx-target={@myself}
                type="text"
                autocomplete="off"
                placeholder="Ask about the meeting"
                class="flex-1 px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <button
              type="submit"
              class="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 text-sm"
            >
              Ask
            </button>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-background">
      <div class="flex-1 overflow-y-auto px-4 py-4">
        <div class="max-w-3xl mx-auto space-y-4"></div>
      </div>

      <div class="border-t bg-background">
        <div class="max-w-3xl mx-auto px-4 py-4"></div>
      </div>
    </div>
    """
  end
end
