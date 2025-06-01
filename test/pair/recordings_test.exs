defmodule Pair.RecordingsTest do
  use Pair.DataCase

  alias Pair.Recordings

  describe "recordings" do
    alias Pair.Recordings.Recording

    import Pair.RecordingsFixtures

    @invalid_attrs %{upload_url: nil, transcription: nil, actions: nil}

    test "list_recordings/0 returns all recordings" do
      recording = recording_fixture()
      assert Recordings.list_recordings() == [recording]
    end

    test "get_recording!/1 returns the recording with given id" do
      recording = recording_fixture()
      assert Recordings.get_recording!(recording.id) == recording
    end

    test "create_recording/1 with valid data creates a recording" do
      valid_attrs = %{
        upload_url: "some upload_url",
        transcription: "some transcription",
        actions: "some actions"
      }

      assert {:ok, %Recording{} = recording} = Recordings.create_recording(valid_attrs)
      assert recording.upload_url == "some upload_url"
      assert recording.transcription == "some transcription"
      assert recording.actions == "some actions"
    end

    test "create_recording/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Recordings.create_recording(@invalid_attrs)
    end

    test "update_recording/2 with valid data updates the recording" do
      recording = recording_fixture()

      update_attrs = %{
        upload_url: "some updated upload_url",
        transcription: "some updated transcription",
        actions: "some updated actions"
      }

      assert {:ok, %Recording{} = recording} =
               Recordings.update_recording(recording, update_attrs)

      assert recording.upload_url == "some updated upload_url"
      assert recording.transcription == "some updated transcription"
      assert recording.actions == "some updated actions"
    end

    test "update_recording/2 with invalid data returns error changeset" do
      recording = recording_fixture()
      assert {:error, %Ecto.Changeset{}} = Recordings.update_recording(recording, @invalid_attrs)
      assert recording == Recordings.get_recording!(recording.id)
    end

    test "delete_recording/1 deletes the recording" do
      recording = recording_fixture()
      assert {:ok, %Recording{}} = Recordings.delete_recording(recording)
      assert_raise Ecto.NoResultsError, fn -> Recordings.get_recording!(recording.id) end
    end

    test "change_recording/1 returns a recording changeset" do
      recording = recording_fixture()
      assert %Ecto.Changeset{} = Recordings.change_recording(recording)
    end
  end
end
