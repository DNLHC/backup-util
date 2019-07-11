defmodule Backup.Interval do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    Backup.init()
    schedule_work()

    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    Backup.backup()
    Backup.clean()
    schedule_work()

    {:noreply, state}
  end

  defp schedule_work do
    timeout = 10 * 60 * 1000
    Process.send_after(self(), :work, timeout)
  end
end
