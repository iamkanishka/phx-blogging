defmodule BloggingWeb.Helpers do
  def truncate(text, max_length \\ 100)

  def truncate(nil, _max_length), do: ""

  def truncate(text, max_length) when is_binary(text) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length) <> "..."
    else
      text
    end
  end
end
