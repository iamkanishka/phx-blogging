defmodule BloggingWeb.UserSettingsLive do
  use BloggingWeb, :live_view

  alias Blogging.Accounts
  alias Blogging.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      module={BloggingWeb.ComponentsLive.Layout}
      id="main-layout"
      current_path={@current_path}
      user_name={@current_user.username}
      has_new_notifications={@has_new_notifications}
    >
      <div class="space-y-12 divide-y">

    <!-- Username + Bio Form -->
        <div>
          <.simple_form
            for={@profile_form}
            id="profile_form"
            phx-submit="update_profile"
            phx-change="validate_profile"
            class="space-y-4"
          >
            <div class="flex flex-wrap gap-4">
              <div class="flex-1 min-w-[200px]">
                <.input field={@profile_form[:username]} type="text" label="Username" required />
              </div>
              <div class="flex-1 min-w-[200px]">
                <.input field={@profile_form[:bio]} type="textarea" label="Bio" />
              </div>
            </div>
            <:actions>
              <.button phx-disable-with="Saving...">Update Profile</.button>
            </:actions>
          </.simple_form>
        </div>

    <!-- Email Form -->
        <div>
          <.simple_form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
            class="space-y-4"
          >
            <div class="flex flex-wrap gap-4">
              <div class="flex-1 min-w-[200px]">
                <.input field={@email_form[:email]} type="email" label="Email" required />
              </div>
              <div class="flex-1 min-w-[200px]">
                <.input
                  field={@email_form[:current_password]}
                  name="current_password"
                  id="current_password_for_email"
                  type="password"
                  label="Current password"
                  value={@email_form_current_password}
                  required
                />
              </div>
            </div>
            <:actions>
              <.button phx-disable-with="Changing...">Change Email</.button>
            </:actions>
          </.simple_form>
        </div>

    <!-- Password Form -->
        <div>
          <.simple_form
            for={@password_form}
            id="password_form"
            action={~p"/users/log_in?_action=password_updated"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
            class="space-y-4"
          >
            <input
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              value={@current_email}
            />
            <div class="flex flex-wrap gap-4">
              <div class="flex-1 min-w-[200px]">
                <.input
                  field={@password_form[:password]}
                  type="password"
                  label="New password"
                  required
                />
              </div>
              <div class="flex-1 min-w-[200px]">
                <.input
                  field={@password_form[:password_confirmation]}
                  type="password"
                  label="Confirm new password"
                />
              </div>
              <div class="flex-1 min-w-[200px]">
                <.input
                  field={@password_form[:current_password]}
                  name="current_password"
                  type="password"
                  label="Current password"
                  id="current_password_for_password"
                  value={@current_password}
                  required
                />
              </div>
            </div>
            <:actions>
              <.button phx-disable-with="Changing...">Change Password</.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </.live_component>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok -> put_flash(socket, :info, "Email changed successfully.")
        :error -> put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/profile/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:current_user, user)
      |> assign(:email_form, to_form(Accounts.change_user_email(user)))
      |> assign(:password_form, to_form(Accounts.change_user_password(user)))
      |> assign(:profile_form, to_form(User.change_user_profile(user)))
      |> assign(:trigger_submit, false)
       |> assign(:has_new_notifications, false)


    {:ok, socket}
  end

  @impl true
  def handle_params(_unsigned_params, url, socket) do
    {:noreply, assign(socket, current_path: URI.parse(url).path)}
  end

  # Email
  @impl true
  def handle_event("validate_email", %{"current_password" => pwd, "user" => user_params}, socket) do
    changeset = Accounts.change_user_email(socket.assigns.current_user, user_params)

    {:noreply,
     assign(socket,
       email_form: to_form(%{changeset | action: :validate}),
       email_form_current_password: pwd
     )}
  end

  def handle_event("update_email", %{"current_password" => pwd, "user" => user_params}, socket) do
    case Accounts.apply_user_email(socket.assigns.current_user, pwd, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          socket.assigns.current_user.email,
          &url(~p"/profile/settings/confirm_email/#{&1}")
        )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "A link to confirm your email change has been sent to the new address."
         )
         |> assign(:email_form_current_password, nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(%{changeset | action: :insert}))}
    end
  end

  # Password
  def handle_event(
        "validate_password",
        %{"current_password" => pwd, "user" => user_params},
        socket
      ) do
    changeset = Accounts.change_user_password(socket.assigns.current_user, user_params)

    {:noreply,
     assign(socket,
       password_form: to_form(%{changeset | action: :validate}),
       current_password: pwd
     )}
  end

  def handle_event("update_password", %{"current_password" => pwd, "user" => user_params}, socket) do
    case Accounts.update_user_password(socket.assigns.current_user, pwd, user_params) do
      {:ok, updated_user} ->
        changeset = Accounts.change_user_password(updated_user)
        {:noreply, assign(socket, trigger_submit: true, password_form: to_form(changeset))}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  # Username + Bio
  def handle_event("validate_profile", %{"user" => attrs}, socket) do
    changeset = User.change_user_profile(socket.assigns.current_user, attrs)
    {:noreply, assign(socket, profile_form: to_form(%{changeset | action: :validate}))}
  end

  def handle_event("update_profile", %{"user" => attrs}, socket) do
    case User.update_user_profile(socket.assigns.current_user, attrs) do
      {:ok, updated_user} ->
        changeset = User.change_user_profile(updated_user)

        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully.")
         |> assign(user: updated_user, profile_form: to_form(changeset))}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_info(%{event: "render_new_notification_badge", payload: %{notification: _notification}}, socket) do
  IO.inspect("Received new notification badge")
  {:noreply, assign(socket, :has_new_notifications, true)}
end
end
