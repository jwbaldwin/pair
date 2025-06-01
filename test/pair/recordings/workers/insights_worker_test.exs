defmodule Pair.Recordings.Workers.InsightsWorkerTest do
  use Pair.DataCase, async: true
  use Oban.Testing, repo: Pair.Repo

  alias Pair.Clients.Anthropic
  alias Pair.Recordings
  alias Pair.Recordings.Workers.InsightsWorker

  import Mimic

  setup :verify_on_exit!

  describe "perform/1" do
    test "successfully generates actions and structured meeting notes" do
      # Create a test recording with transcription
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          transcription: "John and Sarah discussed the project timeline and budget.",
          status: :transcribed
        })

      # Mock Anthropic actions generation
      expected_actions = """
      📌 ACTION ITEMS
      • John — Review project requirements — By Friday
      • Sarah — Prepare budget proposal — Next week

      📋 KEY FACTS
      • Project timeline: 6 weeks
      • Budget range: $50k-75k
      """

      Anthropic
      |> expect(:generate_actions, fn transcription ->
        assert transcription == "John and Sarah discussed the project timeline and budget."
        {:ok, expected_actions}
      end)

      job_args = %{"id" => recording.id}
      assert :ok = perform_job(InsightsWorker, job_args)

      updated_recording = Recordings.get_recording!(recording.id)
      assert updated_recording.actions == expected_actions
      assert updated_recording.status == :analyzed
    end

    test "handles Anthropic API errors gracefully" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/audio.wav",
          transcription: "Test transcription",
          status: :transcribed
        })

      Anthropic
      |> expect(:generate_actions, fn _transcription ->
        {:error, "API rate limit exceeded"}
      end)

      log =
        capture_log(fn ->
          job_args = %{"id" => recording.id}
          assert {:error, "API rate limit exceeded"} = perform_job(InsightsWorker, job_args)
        end)

      assert log =~ "Failed to process recording #{recording.id}: \"API rate limit exceeded\""

      updated_recording = Recordings.get_recording!(recording.id)
      assert updated_recording.status == :error
      assert updated_recording.actions == nil
    end

    test "handles recording not found" do
      non_existent_id = UUIDv7.generate()

      Anthropic
      |> reject(:generate_actions, 1)

      job_args = %{"id" => non_existent_id}

      log =
        capture_log(fn ->
          assert {:error, :not_found} = perform_job(InsightsWorker, job_args)
        end)

      assert log =~ "Failed to process recording #{non_existent_id}: :not_found"
    end
  end

  describe "enqueue/1" do
    test "creates actions job with correct arguments" do
      {:ok, recording} =
        Recordings.create_recording(%{
          upload_url: "https://example.com/test.wav",
          transcription: "Test transcription"
        })

      assert {:ok, %Oban.Job{} = job} = InsightsWorker.enqueue(recording)
      assert job.args == %{id: recording.id}
      assert job.worker == "Pair.Recordings.Workers.InsightsWorker"
    end
  end
end
