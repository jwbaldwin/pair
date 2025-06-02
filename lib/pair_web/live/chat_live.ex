defmodule PairWeb.ChatLive do
  use PairWeb, :live_view

  alias Pair.Clients.Anthropic

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       messages: [],
       form: to_form(%{"message" => ""})
     )}
  end

  def handle_event("change", %{"message" => message}, socket) do
    {:noreply, assign(socket, form: to_form(%{"message" => message}))}
  end

  @impl true
  def handle_event("send", %{"message" => message}, socket) when message != "" do
    messages = socket.assigns.messages ++ [%{role: :user, content: message}]

    Task.start(fn ->
      Anthropic.stream_response(self(), messages)
    end)

    {:noreply,
     socket
     |> assign(:messages, messages)
     |> assign(:form, to_form(%{"message" => ""}))}
  end

  def handle_event("send", _, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:stream_chunk, chunk}, socket) do
    [head | rest] = Enum.reverse(socket.assigns.messages)
    updated_message = %{head | content: head.content <> chunk}
    updated_messages = Enum.reverse([updated_message | rest])

    {:noreply, assign(socket, :messages, updated_messages)}
  end

  @impl true
  def handle_info({:stream_start}, socket) do
    {:noreply,
     assign(socket, :messages, socket.assigns.messages ++ [%{role: :assistant, content: ""}])}
  end

  @impl true
  def handle_info({:stream_complete}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-background">
      <div class="flex-1 overflow-y-auto px-4 py-4">
        <div class="max-w-3xl mx-auto space-y-4">
          <%= for message <- @messages do %>
            <%= if message.role == :assistant do %>
              <div class="flex gap-3 items-start">
                <div class="shrink-0 mt-0.5">
                  <div class="h-8 w-8 rounded-full bg-primary flex items-center justify-center">
                    <span class="text-primary-foreground text-xs font-medium">A</span>
                  </div>
                </div>
                <div class="flex">
                  <div class="bg-card rounded-lg px-4 py-3 shadow-sm border border-gray-200">
                    <p class="text-card-foreground text-sm">{message.content}</p>
                  </div>
                </div>
              </div>
            <% else %>
              <div class="flex gap-3 items-start">
                <div class="flex">
                  <div class="bg-muted rounded-lg px-4 py-3 ml-auto">
                    <p class="text-foreground text-sm">{message.content}</p>
                  </div>
                </div>
                <div class="shrink-0 mt-0.5">
                  <div class="h-8 w-8 rounded-full bg-secondary flex items-center justify-center">
                    <span class="text-secondary-foreground text-xs font-medium">Y</span>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>

      <div class="border-t bg-background">
        <div class="max-w-3xl mx-auto px-4 py-4">
          <.form for={@form} phx-submit="send" phx-change="change" class="flex gap-2 items-center">
            <div class="flex-1 relative">
              <.input
                field={@form[:message]}
                phx-debounce="200"
                type="text"
                autocomplete="off"
                placeholder="Message..."
                class="w-full px-3 py-2 h-10 rounded-md border border-input bg-background text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
              />
            </div>
            <button
              type="submit"
              class="inline-flex items-center justify-center rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4"
            >
              Send
            </button>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
