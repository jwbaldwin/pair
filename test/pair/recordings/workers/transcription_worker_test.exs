defmodule Pair.Recordings.Workers.TranscriptionWorkerTest do
  use Pair.DataCase
  use Oban.Testing, repo: Pair.Repo
  use Mimic

  alias Pair.Recordings
  alias Pair.Recordings.Workers.TranscriptionWorker

  describe "TranscriptionWorker" do
    setup do
      recording = insert(:recording)

      {:ok, recording: recording}
    end

    test "enqueue/1 creates an Oban job", %{recording: recording} do
      assert {:ok, %Oban.Job{}} = TranscriptionWorker.enqueue(recording)

      assert_enqueued(
        worker: TranscriptionWorker,
        args: %{id: recording.id, upload_url: recording.upload_url}
      )
    end

    test "perform/1 processes the recording and updates transcription", %{recording: recording} do
      # Mock the Req.post! function
      Req
      |> expect(:post!, fn _, _ ->
        %{
          body: %{
            "text" => "This is a test transcription from OpenAI."
          }
        }
      end)

      # Execute the job
      args = %{"id" => recording.id, "upload_url" => recording.upload_url}
      assert :ok = perform_job(TranscriptionWorker, args)

      # Verify the recording was updated
      updated_recording = Recordings.get_recording!(recording.id)

      assert updated_recording.transcription == %{
               "text" => "This is a test transcription from OpenAI."
             }
    end

    test "perform/1 handles recording not found" do
      # Mock Req.post! to avoid real API calls
      Req
      |> expect(:post!, fn _, _ ->
        %{body: %{"text" => "Test transcription"}}
      end)

      # Create args with a non-existent ID
      args = %{
        "id" => UUIDv7.generate(),
        "upload_url" => "test/support/fixtures/recording.wav"
      }

      # The job should complete without errors, even though the recording isn't found
      assert :ok = perform_job(TranscriptionWorker, args)
    end
  end
end
