defmodule PairWeb.AudioUploadControllerTest do
  use PairWeb.ConnCase, async: true

  @fixture_path "test/support/fixtures/recording.wav"

  setup do
    File.mkdir_p!("uploads")

    on_exit(fn ->
      Path.wildcard("uploads/*_recording.wav") |> Enum.each(&File.rm/1)
    end)
  end

  test "create stores the audio locally", %{conn: conn} do
    upload = %Plug.Upload{
      path: @fixture_path,
      filename: "recording.wav",
      content_type: "audio/wav"
    }

    data =
      conn
      |> post(~p"/api/audio", %{file: upload})
      |> json_response(201)
      |> Map.get("data")

    assert data["upload_url"]
    assert String.ends_with?(data["upload_url"], "recording.wav")

    file_path = data["upload_url"]
    assert File.exists?(file_path)
  end
end
