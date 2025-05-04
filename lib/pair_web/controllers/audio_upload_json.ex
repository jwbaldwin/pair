defmodule PairWeb.AudioUploadJSON do
  def show(%{recording: recording}) do
    %{
      data: %{
        upload_url: recording.upload_url
      }
    }
  end
end
