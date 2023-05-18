defmodule Chat.ChatGptClient do
  require Logger

  @endpoint "https://api.openai.com/v1/chat/completions"

  def chat(token, content) do
    case HTTPoison.post(
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
         ) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> Map.get("choices")
        |> Enum.map(&get_in(&1, ["message", "content"]))
        |> Enum.join("\n\n")
        |> (&{:ok, &1}).()

      _ ->
        {:error, "Invalid Token!"}
    end
  end
end
