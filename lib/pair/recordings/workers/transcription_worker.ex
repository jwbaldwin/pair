defmodule Pair.Recordings.Workers.TranscriptionWorker do
  use Oban.Worker

  alias Pair.Recordings
  alias Pair.Recordings.Recording

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "upload_url" => upload_url}}) do
    IO.inspect(upload_url)

    whisper_api =
      Req.new(
        base_url: "https://api.openai.com/v1/audio/transcriptions",
        headers: %{
          "Authorization" => "Bearer #{Application.get_env(:pair, :openai_api_key)}",
          "Content-Type" => "multipart/form-data"
        }
      )

    resp =
      Req.post!(whisper_api,
        form: [
          file: {:file, upload_url},
          model: "gpt-4o-transcribe"
        ]
      )

    IO.inspect(resp)

    with {:ok, recording} <- Recordings.fetch_recording(id) do
      Recordings.update_recording(recording, %{transcription: resp.body})
    end
  end

  @doc """
  Enqueue a transcription job for the given upload_url.
  Worker will send the recording to OpenAI for transcription.
  """
  @spec enqueue(Recording.t()) :: Oban.Job.t()
  def enqueue(recording) do
    %{id: recording.id, upload_url: recording.upload_url}
    |> new()
    |> Oban.insert()
  end
end
