defmodule Pair.Recordings do
  @moduledoc """
  The Recordings context.
  """

  import Ecto.Query, warn: false
  alias Pair.Repo

  alias Pair.Recordings.Recording
  alias Phoenix.PubSub

  @doc """
  Returns the list of recordings.

  ## Examples

      iex> list_recordings()
      [%Recording{}, ...]

  """
  def list_recordings do
    Repo.all(Recording)
  end

  def list_recordings_by_date do
    recordings =
      from(r in Recording, order_by: [desc: r.inserted_at])
      |> Repo.all()

    recordings
    |> Enum.reduce([], fn rec, acc ->
      date = DateTime.to_date(rec.inserted_at)

      case acc do
        [{^date, todays} | rest] ->
          [{date, [rec | todays]} | rest]

        _ ->
          [{date, [rec]} | acc]
      end
    end)
    |> Enum.reverse()
  end

  @doc """
  Gets a single recording.

  Raises `Ecto.NoResultsError` if the Recording does not exist.

  ## Examples

      iex> get_recording!(123)
      %Recording{}

      iex> get_recording!(456)
      ** (Ecto.NoResultsError)

  """
  def get_recording!(id), do: Repo.get!(Recording, id)

  @doc """
  Gets a single recording.

  Returns `{:ok, recording}` if the recording exists, `{:error, :not_found}` otherwise.

  ## Examples

      iex> fetch_recording(123)
      {:ok, %Recording{}}

      iex> fetch_recording(456)
      {:error, :not_found}

  """
  def fetch_recording(id) do
    case Repo.get(Recording, id) do
      nil -> {:error, :not_found}
      recording -> {:ok, recording}
    end
  end

  @doc """
  Gets a single recording with its meeting notes already encoded as JSON
  """
  @spec fetch_recording_with_meeting_notes(Recording.id()) ::
          {:ok, Recording.t()} | {:error, any()}
  def fetch_recording_with_meeting_notes(id) do
    with {:ok, recording} <- fetch_recording(id) do
      notes = recording.meeting_notes || "{}"
      {:ok, recording |> Map.put(:meeting_notes, Jason.decode!(notes))}
    end
  end

  @doc """
  Creates a recording.

  ## Examples

      iex> create_recording(%{field: value})
      {:ok, %Recording{}}

      iex> create_recording(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_recording(attrs \\ %{}) do
    %Recording{}
    |> Recording.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, recording} ->
        broadcast_recording_updated!(recording)

        {:ok, recording}

      error ->
        error
    end
  end

  @doc """
  Updates a recording.

  ## Examples

      iex> update_recording(recording, %{field: new_value})
      {:ok, %Recording{}}

      iex> update_recording(recording, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_recording(%Recording{} = recording, attrs) do
    recording
    |> Recording.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, updated_recording} ->
        broadcast_recording_updated!(updated_recording)
        {:ok, updated_recording}

      error ->
        error
    end
  end

  @doc """
  Deletes a recording.

  ## Examples

      iex> delete_recording(recording)
      {:ok, %Recording{}}

      iex> delete_recording(recording)
      {:error, %Ecto.Changeset{}}

  """
  def delete_recording(%Recording{} = recording) do
    Repo.delete(recording)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking recording changes.

  ## Examples

      iex> change_recording(recording)
      %Ecto.Changeset{data: %Recording{}}

  """
  def change_recording(%Recording{} = recording, attrs \\ %{}) do
    Recording.changeset(recording, attrs)
  end

  def broadcast_recording_updated!(recording) do
    PubSub.broadcast!(
      Pair.PubSub,
      "recordings:updates",
      {:recording_updated, %{recording_id: recording.id}}
    )
  end
end
