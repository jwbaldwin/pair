defmodule PairWeb.Dashboard.Navbar do
  use PairWeb, :html

  def navbar(assigns) do
    ~H"""
    <nav class="flex items-center justify-between">
      <h1 class="text-xl font-semibold text-stone-900">Recordings</h1>
      <.link
        navigate={~p"/templates"}
        class="inline-flex items-center px-3 py-2 text-sm font-medium text-stone-600 hover:text-stone-900 hover:bg-stone-100 rounded-md transition-colors duration-150"
      >
        <.icon name="template-doc" class="h-5 w-5 mr-1" /> Templates
      </.link>
    </nav>
    """
  end
end
