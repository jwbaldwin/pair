defmodule Pair.Clients.Anthropic do
  @moduledoc """
  Req client for Anthropic API that simply take a conversation
  and stream the response back to the caller.
  """

  alias Pair.Clients.Prompts

  require Logger

  @base_url "https://api.anthropic.com/v1"
  @api_version "2023-06-01"
  @default_model "claude-sonnet-4-20250514"
  @default_max_tokens 1024

  defp client(opts \\ []) do
    path = Keyword.get(opts, :path, "/messages")

    Req.new(
      base_url: @base_url <> path,
      headers: %{
        "x-api-key" => Application.get_env(:pair, :anthropic_api_key),
        "anthropic-version" => @api_version,
        "content-type" => "application/json"
      }
    )
  end

  @doc """
  Makes a non-streaming request to Anthropic's API with
  a system prompt for generating actions.
  """
  @spec generate_actions(String.t()) :: {:ok, String.t()} | {:error, any()}
  def generate_actions(transcription) do
    body = %{
      model: @default_model,
      max_tokens: @default_max_tokens,
      system: Prompts.test_transcript(),
      messages: [
        %{
          role: "user",
          content: "Here is the transcription: #{transcription}"
        }
      ]
    }

    res = Req.post!(client(), json: body)

    case res do
      %{status: 200} ->
        text_content =
          case res.body do
            %{"content" => [%{"text" => text, "type" => "text"} | _]} ->
              text

            %{"content" => content} when is_list(content) ->
              content
              |> Enum.filter(fn item -> Map.get(item, "type") == "text" end)
              |> Enum.map(fn item -> Map.get(item, "text", "") end)
              |> Enum.join("\n")

            _ ->
              Logger.warning(
                "Unexpected response format from Anthropic API: #{inspect(res.body)}"
              )

              ""
          end

        {:ok, text_content}

      %{status: status} ->
        Logger.error("Error: Response from Anthropic API: #{status} - #{inspect(res.body)}")
        {:error, "Anthropic API error: #{status} - #{inspect(res.body)}"}
    end
  end

  @doc """
  Streams a response from Anthropic's API back to the caller.
  """
  @spec stream_response(pid(), list(map())) :: :ok | {:error, any()}
  def stream_response(pid, conversation) do
    body = %{
      model: @default_model,
      max_tokens: @default_max_tokens,
      messages: conversation,
      stream: true
    }

    Req.post!(client(),
      json: body,
      into: fn {:data, data}, {req, res} ->
        case res do
          %{status: 200} ->
            buffer = Req.Request.get_private(req, :sse_buffer, "")
            {events, buffer} = ServerSentEvents.parse(buffer <> data)
            req = Req.Request.put_private(req, :sse_buffer, buffer)

            process_sse_events(events, pid)

            {:cont, {req, res}}

          %{status: status} ->
            Logger.error("Error: Response from Anthropic API: #{status} - #{inspect(res)}")
            {:halt, {req, res}}
        end
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

        "message_start" ->
          send(pid, {:stream_start})

        _message_stop_or_message_delta ->
          nil
      end
    end)
  end
end
