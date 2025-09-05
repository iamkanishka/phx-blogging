defmodule Blogging.Emails.Emails do
  alias Blogging.Emails.WelcomeEmail


  @spec send_welcome_email(any()) :: none()
  def send_welcome_email(user) do
    WelcomeEmail.send_welcome(user)
    # |> Mailer.deliver()
  end

  # Async version using Task
  def send_welcome_email_async(user) do
    Task.start(fn ->
      send_welcome_email(user)
    end)
  end
end
