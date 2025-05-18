defmodule Pair.Clients.OpenAI do
  @moduledoc """
  Req client for OpenAI API
  """

  @spec transcribe(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def transcribe(upload_url) do
    openai_api =
      Req.new(
        base_url: "https://api.openai.com/v1/audio/transcriptions",
        headers: %{
          "Authorization" => "Bearer #{Application.get_env(:pair, :openai_api_key)}"
        }
      )

    file_content = File.read!(upload_url)
    filename = Path.basename(upload_url)

    resp =
      Req.post!(
        openai_api,
        form_multipart: [
          file: {file_content, filename: filename, content_type: "audio/wave"},
          model: "gpt-4o-transcribe",
          response_format: "text"
        ]
      )

    case resp.status do
      200 -> {:ok, resp.body}
      _ -> {:error, "OpenAI API error: #{resp.status} - #{resp.body}"}
    end
  end
end
