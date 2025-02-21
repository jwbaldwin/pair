defmodule PairWeb.DashboardLive do
  use PairWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-3xl font-semibold text-gray-900">Dashboard</h1>
          <p class="mt-2 text-sm text-gray-700">
            Welcome to your dashboard.
          </p>
        </div>
      </div>
      <div class="mt-8">
        <!-- Dashboard content will go here -->
      </div>
    </div>
    """
  end
end
