defmodule GramexParrot.TelegramBot do
  use GenServer
  require Logger

  @api_base Application.compile_env(
              :gramex_parrot,
              :telegram_api_base,
              "https://api.telegram.org"
            )

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    token = Application.fetch_env!(:gramex_parrot, :telegram_bot_token)

    if is_nil(token) do
      Logger.error("TELEGRAM_BOT_TOKEN environment variable is not set")
      {:stop, :no_token}
    else
      state = %{token: token, offset: 0}
      # Start polling in init
      poll_updates(state)
      {:ok, state}
    end
  end

  defp poll_updates(state) do
    # Spawn a process to handle polling so we don't block the GenServer
    parent = self()

    spawn_link(fn ->
      case get_updates(state.token, state.offset) do
        {:ok, updates} ->
          send(parent, {:updates, updates})

        {:error, reason} ->
          Logger.error("Failed to get updates: #{inspect(reason)}")
          # Wait a bit before retrying
          Process.sleep(1000)
          send(parent, :retry)
      end
    end)
  end

  @impl true
  def handle_info({:updates, updates}, state) do
    new_offset = process_updates(updates, state.token, state.offset)
    new_state = %{state | offset: new_offset}

    # Continue polling
    poll_updates(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:retry, state) do
    poll_updates(state)
    {:noreply, state}
  end

  defp get_updates(token, offset) do
    url = "#{@api_base}/bot#{token}/getUpdates"

    params = %{
      offset: offset,
      # Long polling timeout in seconds
      timeout: 60
    }

    case Req.post(url, json: params) do
      {:ok, %{status: 200, body: %{"ok" => true, "result" => result}}} ->
        {:ok, result}

      {:ok, %{status: status, body: body}} ->
        {:error, "HTTP #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp process_updates([], _token, offset), do: offset

  defp process_updates(updates, token, _offset) do
    Enum.each(updates, fn update ->
      handle_update(update, token)
    end)

    # Return the next offset (last update_id + 1)
    last_update = List.last(updates)
    last_update["update_id"] + 1
  end

  defp handle_update(%{"message" => %{"text" => text, "chat" => %{"id" => chat_id}}}, token) do
    Logger.info("Received message: #{text} from chat #{chat_id}")
    send_message(token, chat_id, text)
  end

  defp handle_update(_update, _token) do
    # Ignore non-text messages
    :ok
  end

  defp send_message(token, chat_id, text) do
    url = "#{@api_base}/bot#{token}/sendMessage"

    params = %{
      chat_id: chat_id,
      text: text
    }

    case Req.post(url, json: params) do
      {:ok, %{status: 200}} ->
        Logger.info("Sent echo message to chat #{chat_id}")
        :ok

      {:ok, %{status: status, body: body}} ->
        Logger.error("Failed to send message: HTTP #{status}: #{inspect(body)}")
        :error

      {:error, reason} ->
        Logger.error("Failed to send message: #{inspect(reason)}")
        :error
    end
  end
end
