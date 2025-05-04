defmodule Pair.Schema do
  @moduledoc """
  A custom schema def that adds UUIDv6 as default primary key.
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      @primary_key {:id, UUIDv7.Type, autogenerate: true}
      @foreign_key_type UUIDv7.Type
    end
  end
end
