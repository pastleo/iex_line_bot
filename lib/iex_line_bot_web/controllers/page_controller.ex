defmodule IexLineBotWeb.PageController do
  use IexLineBotWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def line(conn, params) do
    process_events(params)
    json(conn, %{ reply: "ok" })
  end

  defp process_events(%{"events" => events}) do
    Enum.each(events, &process_event/1)
  end

  defp process_event(
    %{
      "message" => %{"text" => text, "type" => "text"},
      "replyToken" => replyToken,
      "source" => source
    } # = event
  ) do
    IO.inspect(Application.get_env(:iex_line_bot, :line_access_token))
    response = {
      'https://api.line.me/v2/bot/message/reply', # URL
      [ # headers
        {'Content-Type', 'application/json'},
        {'Authorization', 'Bearer #{Application.get_env(:iex_line_bot, IexLineBotWeb.Endpoint)[:line_access_token]}'}
      ],
      'application/json',
      Jason.encode!(%{
        "replyToken" => replyToken,
        "messages" => [
          %{
            "type" => "text",
            "text" => IexLineBot.string(text, memory_key_from_source(source))
          },
        ]
      }) |> :binary.bin_to_list()
    }
    :httpc.request(:post, response, [], [])
  end

  defp process_event(_), do: nil

  defp memory_key_from_source(%{"type" => "user", "userId" => userId}), do: userId
end
