defmodule Pair.Recordings.Workers.TranscriptionWorkerTest do
  use Pair.DataCase, async: true
  use Oban.Testing, repo: Pair.Repo

  alias Pair.Recordings.Workers.{TranscriptionWorker, InsightsWorker}
  alias Pair.Recordings
  alias Pair.Clients.OpenAI

  import Mimic

  setup :verify_on_exit!

  describe "perform/1" do
    test "successfully transcribes recording and enqueues actions worker" do
      # Create a test recording
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          status: :uploaded
        })

      # Mock OpenAI transcription
      OpenAI
      |> expect(:transcribe, fn url ->
        assert url == "https://example.com/audio.wav"
        {:ok, "This is the transcribed text from the audio file."}
      end)

      # Mock InsightsWorker.enqueue to avoid actual job creation
      InsightsWorker
      |> expect(:enqueue, fn worker_recording ->
        assert worker_recording.id == recording.id
        %Oban.Job{id: 123}
      end)

      # Perform the job
      job_args = %{"id" => recording.id, "upload_url" => recording.upload_url}
      assert :ok = perform_job(TranscriptionWorker, job_args)

      # Verify recording was updated
      updated_recording = Recordings.get_recording!(recording.id)

      assert updated_recording.transcription ==
               "This is the transcribed text from the audio file."

      assert updated_recording.status == :transcribed
    end

    test "handles OpenAI transcription errors" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          status: :uploaded
        })

      # Mock OpenAI transcription failure
      OpenAI
      |> expect(:transcribe, fn _url ->
        {:error, "Audio file format not supported"}
      end)

      # Should not call InsightsWorker.enqueue on failure
      InsightsWorker
      |> expect(:enqueue, 0, fn _recording -> %Oban.Job{id: 123} end)

      job_args = %{"id" => recording.id, "upload_url" => recording.upload_url}

      # Job should fail but not raise
      assert {:error, _} = perform_job(TranscriptionWorker, job_args)

      # Verify recording was not updated
      unchanged_recording = Recordings.get_recording!(recording.id)
      assert unchanged_recording.transcription == nil
      assert unchanged_recording.status == :uploaded
    end

    test "handles recording not found" do
      non_existent_id = UUIDv7.generate()

      job_args = %{"id" => non_existent_id, "upload_url" => "https://example.com/audio.wav"}

      # Should handle gracefully
      assert {:error, _} = perform_job(TranscriptionWorker, job_args)
    end

    test "handles recording update failure" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          status: :uploaded
        })

      OpenAI
      |> expect(:transcribe, fn _url ->
        {:ok, "Transcribed text"}
      end)

      # Mock Recordings.update_recording to fail
      Recordings
      |> expect(:update_recording, fn _recording, _attrs ->
        {:error, %Ecto.Changeset{}}
      end)

      InsightsWorker
      |> expect(:enqueue, 0, fn _recording -> %Oban.Job{id: 123} end)

      job_args = %{"id" => recording.id, "upload_url" => recording.upload_url}

      assert {:error, _} = perform_job(TranscriptionWorker, job_args)
    end
  end

  describe "enqueue/1" do
    test "creates transcription job with correct arguments" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/test.wav"
        })

      assert %Oban.Job{} = job = TranscriptionWorker.enqueue(recording)
      assert job.args == %{"id" => recording.id, "upload_url" => recording.upload_url}
      assert job.worker == "Pair.Recordings.Workers.TranscriptionWorker"
    end

    test "job is properly inserted into the database" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/test.wav"
        })

      assert {:ok, job} = TranscriptionWorker.enqueue(recording)

      # Verify job exists in database
      assert Oban.Job |> Pair.Repo.get!(job.id)
    end
  end

  describe "integration test" do
    test "full transcription workflow" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          status: :uploaded
        })

      OpenAI
      |> expect(:transcribe, fn _url ->
        {:ok, "Meeting transcript: John discussed the project timeline with Sarah."}
      end)

      InsightsWorker
      |> expect(:enqueue, fn _recording -> %Oban.Job{id: 456} end)

      # Enqueue and perform the job
      job = TranscriptionWorker.enqueue(recording)
      assert :ok = perform_job(TranscriptionWorker, job.args)

      # Verify the full workflow
      final_recording = Recordings.get_recording!(recording.id)

      assert final_recording.transcription ==
               "Meeting transcript: John discussed the project timeline with Sarah."

      assert final_recording.status == :transcribed
      assert final_recording.upload_url == "https://example.com/audio.wav"
    end
  end
end
