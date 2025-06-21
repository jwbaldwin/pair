defmodule Pair.MeetingTemplates do
  @moduledoc """
  The MeetingTemplates context.
  """

  import Ecto.Query, warn: false
  alias Pair.Repo

  alias Pair.MeetingTemplates.MeetingTemplate

  @doc """
  Returns the list of meeting_templates.

  ## Examples

      iex> list_meeting_templates()
      [%MeetingTemplate{}, ...]

  """
  def list_meeting_templates do
    Repo.all(MeetingTemplate)
  end

  @doc """
  Returns the list of system meeting templates.

  ## Examples

      iex> list_system_templates()
      [%MeetingTemplate{}, ...]

  """
  def list_system_templates do
    MeetingTemplate
    |> where([t], t.is_system_template == true)
    |> Repo.all()
  end

  @doc """
  Gets a single meeting_template.

  Raises `Ecto.NoResultsError` if the Meeting template does not exist.

  ## Examples

      iex> get_meeting_template!(123)
      %MeetingTemplate{}

      iex> get_meeting_template!(456)
      ** (Ecto.NoResultsError)

  """
  def get_meeting_template!(id), do: Repo.get!(MeetingTemplate, id)

  @doc """
  Gets a single meeting_template.

  ## Examples

      iex> get_meeting_template(123)
      {:ok, %MeetingTemplate{}}

      iex> get_meeting_template(456)
      {:error, :not_found}

  """
  def get_meeting_template(id) do
    case Repo.get(MeetingTemplate, id) do
      nil -> {:error, :not_found}
      template -> {:ok, template}
    end
  end

  @doc """
  Creates a meeting_template.

  ## Examples

      iex> create_meeting_template(%{field: value})
      {:ok, %MeetingTemplate{}}

      iex> create_meeting_template(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_meeting_template(attrs \\ %{}) do
    %MeetingTemplate{}
    |> MeetingTemplate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a meeting_template.

  ## Examples

      iex> update_meeting_template(meeting_template, %{field: new_value})
      {:ok, %MeetingTemplate{}}

      iex> update_meeting_template(meeting_template, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_meeting_template(%MeetingTemplate{} = meeting_template, attrs) do
    meeting_template
    |> MeetingTemplate.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a meeting_template.

  ## Examples

      iex> delete_meeting_template(meeting_template)
      {:ok, %MeetingTemplate{}}

      iex> delete_meeting_template(meeting_template)
      {:error, %Ecto.Changeset{}}

  """
  def delete_meeting_template(%MeetingTemplate{} = meeting_template) do
    Repo.delete(meeting_template)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking meeting_template changes.

  ## Examples

      iex> change_meeting_template(meeting_template)
      %Ecto.Changeset{data: %MeetingTemplate{}}

  """
  def change_meeting_template(%MeetingTemplate{} = meeting_template, attrs \\ %{}) do
    MeetingTemplate.changeset(meeting_template, attrs)
  end
end
