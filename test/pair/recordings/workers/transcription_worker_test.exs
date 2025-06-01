defmodule Pair.Recordings.Workers.TranscriptionWorkerTest do
  use Pair.DataCase, async: true
  use Oban.Testing, repo: Pair.Repo

  alias Pair.Recordings.Workers.{TranscriptionWorker, InsightsWorker, MeetingNotesWorker}
  alias Pair.Recordings
  alias Pair.Clients.OpenAI

  import Mimic

  setup :verify_on_exit!

  describe "perform/1" do
    test "successfully transcribes recording and enqueues actions worker" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          status: :uploaded
        })

      OpenAI
      |> expect(:transcribe, fn url ->
        assert url == "https://example.com/audio.wav"
        {:ok, "This is the transcribed text from the audio file."}
      end)

      job_args = %{"id" => recording.id, "upload_url" => recording.upload_url}
      assert :ok = perform_job(TranscriptionWorker, job_args)

      # Verify recording was updated
      updated_recording = Recordings.get_recording!(recording.id)

      assert updated_recording.transcription ==
               "This is the transcribed text from the audio file."

      assert updated_recording.status == :transcribed

      assert_enqueued(worker: InsightsWorker, args: %{"id" => recording.id})
      assert_enqueued(worker: MeetingNotesWorker, args: %{"id" => recording.id})
    end

    test "handles OpenAI transcription errors" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          status: :uploaded
        })

      OpenAI
      |> expect(:transcribe, fn _url ->
        {:error, "Audio file format not supported"}
      end)

      job_args = %{"id" => recording.id, "upload_url" => recording.upload_url}

      assert {:error, _} = perform_job(TranscriptionWorker, job_args)

      unchanged_recording = Recordings.get_recording!(recording.id)
      assert unchanged_recording.transcription == nil
      assert unchanged_recording.status == :uploaded

      refute_enqueued(worker: InsightsWorker)
      refute_enqueued(worker: MeetingNotesWorker)
    end

    test "handles recording not found" do
      non_existent_id = UUIDv7.generate()

      job_args = %{"id" => non_existent_id, "upload_url" => "https://example.com/audio.wav"}

      assert {:error, _} = perform_job(TranscriptionWorker, job_args)
    end
  end

  describe "enqueue/1" do
    test "creates transcription job with correct arguments" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/test.wav"
        })

      assert {:ok, %Oban.Job{} = job} = TranscriptionWorker.enqueue(recording)
      assert job.args == %{id: recording.id, upload_url: recording.upload_url}
      assert job.worker == "Pair.Recordings.Workers.TranscriptionWorker"
    end
  end
end
