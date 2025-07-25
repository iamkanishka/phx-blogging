defmodule BloggingWeb.UserRegistrationLive do
  use BloggingWeb, :live_view

  alias Blogging.Accounts
  alias Blogging.Accounts.User

  @all_topics [
    "Software Engineering",
    "Angular",
    "Nestjs",
    "Elixir",
    "Phoenix",
    "Go",
    "Solidity",
    "Astronomy",
    "Blockchain",
    "Finance",
    "Healtcare"
  ]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <.header class="text-center">
        Register for an account
        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
            Log in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <div class="grid grid-cols-2 gap-4">
          <.input field={@form[:username]} type="text" label="User Name" required />
          <.input field={@form[:email]} type="email" label="Email" required />
        </div>

        <div class="grid grid-cols-2 gap-4 mt-4">
          <.input field={@form[:password]} type="password" label="Password" required />
          <.input field={@form[:bio]} type="text" label="Short Bio" required />
        </div>

        <div>
          <h3 class="text-lg font-semibold mb-4">Recommended topics</h3>
          <div class="flex flex-wrap gap-2">
            <%= for topic <- @all_topics do %>
              <% selected = topic in @selected_topics %>
              <span
                phx-click="toggle-topic"
                phx-value-topic={topic}
                class={[
                  "text-sm px-3 py-1 rounded-full cursor-pointer",
                  selected && "bg-blue-500 text-white",
                  !selected && "bg-gray-100 text-gray-700 hover:bg-gray-200"
                ]}
              >
                {topic}
              </span>
            <% end %>
          </div>
        </div>

        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full mt-2">
            Create an account
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(
        trigger_submit: false,
        check_errors: false,
        all_topics: @all_topics,
        selected_topics: []
      )
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    user_params = Map.put(user_params, "intrests", socket.assigns.selected_topics)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
         {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  @impl true
  def handle_event("toggle-topic", %{"topic" => topic}, socket) do
    selected =
      if topic in socket.assigns.selected_topics do
        List.delete(socket.assigns.selected_topics, topic)
      else
        [topic | socket.assigns.selected_topics]
      end

    {:noreply, assign(socket, selected_topics: selected)}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
