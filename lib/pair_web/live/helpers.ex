defmodule PairWeb.Helpers do
  @moduledoc """
  Collection of formatting and utility functions for LiveViews
  """

  alias Pair.Recordings

  @doc """
  Formats a date into a readable header string.
  Returns "Today" for the current date, "Yesterday" for the previous day,
  or a formatted date string (e.g., "Mon Jan 01") for other dates.
  """
  @spec format_date_header(Date.t()) :: String.t()
  def format_date_header(date) do
    today = Date.utc_today()
    yesterday = Date.add(today, -1)

    cond do
      Date.compare(date, today) == :eq -> "Today"
      Date.compare(date, yesterday) == :eq -> "Yesterday"
      true -> Calendar.strftime(date, "%a %b %d")
    end
  end

  @doc """
  Formats a datetime into a readable time string in the America/New_York timezone.
  Returns a string in the format "1:30 PM" (without leading zeros in the hour).
  """
  @spec format_time(DateTime.t()) :: String.t()
  def format_time(datetime) do
    datetime
    |> DateTime.shift_zone!("America/New_York")
    |> Calendar.strftime("%I:%M %p")
    |> String.replace_leading("0", "")
  end

  @doc """
  Extracts the filename from a URL string.
  """
  @spec extract_filename(String.t()) :: String.t()
  def extract_filename(nil), do: "Unknown file"

  def extract_filename(url) do
    url |> String.split("/") |> List.last()
  end

  @doc """
  Maps a status to a set of colors for styling.
  """
  @spec status_color(Recordings.status()) :: String.t()
  def status_color(:uploaded), do: "bg-gray-100 text-gray-800"
  def status_color(:transcribed), do: "bg-blue-100 text-blue-800"
  def status_color(:analyzed), do: "bg-emerald-100 text-emerald-800"
  def status_color(:error), do: "bg-red-100 text-red-800"
  def status_color(:completed), do: "bg-green-100 text-green-800"
end
