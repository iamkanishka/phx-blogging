defmodule Blogging.Emails.WelcomeEmail do
  @moduledoc """
  Handles sending welcome emails via Resend.
  """

  @from "Realblogging <onboarding@resend.dev>" # change to your verified sender

  @spec send_welcome(any()) ::
          {:error, :client_error | Resend.Error.t()} | {:ok, Resend.Emails.Email.t()}
def send_welcome(user) do
    client = Resend.client(api_key: System.get_env("RESEND_API_KEY"))

    case Resend.Emails.send(client, %{
           from: @from,
           to: ["kanishkabc123@gmail.com"], # only works to your gmail for now
           subject: "Welcome to Realblogging, #{user.username}! 🎉",
           html: welcome_html(user),
           text: welcome_text(user)
         }) do
      {:ok, email} ->
        IO.inspect(email, label: "✅ Email sent")

      {:error, err} ->
        IO.inspect(err, label: "❌ Email failed")
    end
  end

  defp welcome_html(user) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: #f9f9f9; padding: 30px; }
        .header { background: #4F46E5; color: white; padding: 20px; text-align: center; }
        .button { background: #4F46E5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Welcome to Realblogging!</h1>
        </div>
        <p>Hello #{user.username},</p>
        <p>Thank you for joining our community. We're excited to have you on board!</p>
        <p>
          <a href="https://myapp.com/dashboard" class="button">Go to Dashboard</a>
        </p>
      </div>
    </body>
    </html>
    """
  end

  defp welcome_text(user) do
    """
    Welcome to Realblogging!

    Hello #{user.username},

    Thank you for joining our community. We're excited to have you on board!

    Get started by visiting your dashboard: https://myapp.com/dashboard

    Best regards,
    The Realblogging Team
    """
  end
end
