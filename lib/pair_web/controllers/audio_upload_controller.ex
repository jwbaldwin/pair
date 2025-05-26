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
    # / update swift app to post to this endpoint
    # / record input and output
    # / we should enable channels so that as the workers complete they broadcast and update the UI
    # / redo the ui to show recordings and show details
    # / separate recording page with chat
    # - update data to use actual datqa from recording
    # - update system prompt
    # - get title from AI and add to recording
    # - wire up chat to recording page
    # - when a new item is added to the UI it should have special styling
    # we should consolidate recordings and chat, not sure how

    # - Once a recording is done, we should do something - notify?
    with {:ok, recording} <- SaveRecording.call(file) do
      conn
      |> put_status(:created)
      |> render("show.json", recording: recording)
    end
  end
end
