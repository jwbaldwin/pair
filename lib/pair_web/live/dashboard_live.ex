defmodule PairWeb.DashboardLive do
  use PairWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       messages: [
         %{role: :assistant, content: "yo"}
       ],
       form: to_form(%{"message" => ""})
     )}
  end

  def handle_event("change", %{"message" => message}, socket) do
    {:noreply, assign(socket, form: to_form(%{"message" => message}))}
  end

  @impl true
  def handle_event("send", %{"message" => message}, socket) when message != "" do
    messages = socket.assigns.messages ++ [%{role: :user, content: message}]

    messages = messages ++ [%{role: :assistant, content: ""}]

    pid = self()

    Task.start(fn ->
      stream_response_from_anthropic(message, pid)
    end)

    {:noreply,
     socket
     |> assign(:messages, messages)
     |> assign(:form, to_form(%{"message" => ""}))}
  end

  def handle_event("send", _, socket), do: {:noreply, socket}

  defp stream_response_from_anthropic(message, pid) do
    anthropic_api =
      Req.new(
        base_url: "https://api.anthropic.com/v1/messages",
        headers: %{
          "x-api-key" => "",
          "anthropic-version" => "2023-06-01",
          "content-type" => "application/json"
        }
      )

    body = %{
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 1024,
      messages: [%{role: "user", content: message}],
      stream: true
    }

    Req.post!(anthropic_api,
      json: body,
      into: fn {:data, data}, {req, res} ->
        buffer = Req.Request.get_private(req, :sse_buffer, "")
        {events, buffer} = ServerSentEvents.parse(buffer <> data)
        req = Req.Request.put_private(req, :sse_buffer, buffer)

        process_sse_events(events, pid)

        {:cont, {req, res}}
      end
    )
  end

  defp process_sse_events([], _pid), do: "No content received."

  defp process_sse_events(events, pid) do
    Enum.each(events, fn event ->
      case event.event do
        "content_block_stop" ->
          send(pid, {:stream_complete})

        "content_block_delta" ->
          case Jason.decode(event.data) do
            {:ok, %{"delta" => %{"text" => text}}} ->
              send(pid, {:stream_chunk, text})

            _ ->
              nil
          end

        _message_start ->
          nil
      end
    end)
  end

  @impl true
  def handle_info({:stream_chunk, chunk}, socket) do
    messages = socket.assigns.messages
    last_index = length(messages) - 1

    last_message = Enum.at(messages, last_index)

    updated_message = %{last_message | content: last_message.content <> chunk}

    updated_messages = List.replace_at(messages, last_index, updated_message)

    {:noreply, assign(socket, :messages, updated_messages)}
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
                <div class="flex-shrink-0 mt-0.5">
                  <div class="h-8 w-8 rounded-full bg-primary flex items-center justify-center">
                    <span class="text-primary-foreground text-xs font-medium">A</span>
                  </div>
                </div>
                <div class="flex">
                  <div class="bg-card rounded-lg px-4 py-3 shadow-sm border">
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
                <div class="flex-shrink-0 mt-0.5">
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
