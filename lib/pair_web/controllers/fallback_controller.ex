defmodule PairWeb.FallbackController do
  use PairWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: PairWeb.ErrorJSON)
    |> render(:error, error: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: PairWeb.ErrorJSON)
    |> render(:error, error: "Resource not found")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(json: PairWeb.ErrorJSON)
    |> render(:error, error: "Unauthorized")
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(json: PairWeb.ErrorJSON)
    |> render(:error, error: "Forbidden")
  end

  def call(conn, error) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(json: PairWeb.ErrorJSON)
    |> render(:error, error: error)
  end
end
