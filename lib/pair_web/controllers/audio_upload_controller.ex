defmodule PairWeb.AudioUploadController do
  use PairWeb, :controller

  alias Pair.Recordings.Services.SaveRecording

  action_fallback PairWeb.FallbackController

  def create(conn, %{"file" => file}) do
    # What do we do once we get the audio
    # / bring it in and store in blob storage (local rn)
    # / send to transcription service
    # / receive text back and store file in blob next to audio
    # / take text and send to LLM with prompt
    # / store response in db
    # / create temp route for viewing recordings and their info
    # - Once a recording is done, we should do something - notify?
    #   if we have a sidebar we should update it and tag it nicely as new
    # - update swift app to post to this endpoint
    with {:ok, recording} <- SaveRecording.call(file) do
      conn
      |> put_status(:created)
      |> render("show.json", recording: recording)
    end
  end
end
