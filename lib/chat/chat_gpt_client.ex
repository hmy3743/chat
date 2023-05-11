defmodule Chat.ChatGptClient do
  require Logger

  @endpoint "https://api.openai.com/v1/chat/completions"

  def chat(token, content) do
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
      HTTPoison.post(
        @endpoint,
        Jason.encode!(%{
          model: "gpt-3.5-turbo",
          messages: [%{role: "user", content: content}]
        }),
        [
          {"Content-Type", "application/json"},
          {"Authorization", "Bearer #{token}"}
        ],
        timeout: :infinity,
        recv_timeout: :infinity
      )

    %{"choices" => choices} = Jason.decode!(body)

    choices
    |> Enum.map(&get_in(&1, ["message", "content"]))
    |> Enum.join("\n\n")
  end
end
