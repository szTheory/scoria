defmodule ScoriaWeb.DevAssetWatcher do
  @moduledoc """
  Dev-only watcher that rebuilds the self-contained dashboard asset bundle when
  source styles/scripts change — so a CSS tweak hot-reloads without manually
  running `mix scoria.assets.build`.

  Compiled ONLY in `:dev` (see `elixirc_paths/1` in mix.exs) and started via the
  `:dev_children` application hook (see `config/dev.exs`), so it never ships to
  Hex or runs in an adopter's app.

  ## Flow

      edit assets/css/*.css            (you)
        -> this watcher debounces + runs scoria.assets.build
        -> writes priv/static/scoria/app.css
        -> the existing live_reload pattern `priv/static/scoria/.*css` fires
        -> ScoriaWeb.Assets recompiles (it inlines the CSS at compile time)
        -> browser refreshes (when SCORIA_DEV_LIVE_RELOAD=1; see DevEndpoint)

  The watcher only regenerates the file — it is harmless to the screenshot
  harness even when the browser LiveReloader socket is off. The rebuilt bundle
  lands in `priv/static/scoria/`, which is NOT a watched dir, so there is no
  rebuild loop.

  On macOS Docker the container's native inotify never sees host fs events, so
  when `FILE_SYSTEM_BACKEND=fs_poll` is set (same gate as phoenix_live_reload in
  config/dev.exs) this watcher uses the polling backend too.
  """
  use GenServer
  require Logger

  @watched_dirs ["assets/css", "assets/js"]
  @debounce_ms 150
  @task "scoria.assets.build"

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    dirs =
      @watched_dirs
      |> Enum.map(&Path.expand/1)
      |> Enum.filter(&File.dir?/1)

    fs_opts =
      if System.get_env("FILE_SYSTEM_BACKEND") == "fs_poll",
        do: [backend: :fs_poll],
        else: []

    case dirs != [] and FileSystem.start_link([dirs: dirs] ++ fs_opts) do
      {:ok, watcher} ->
        FileSystem.subscribe(watcher)
        Logger.info("[scoria] asset watcher: rebuilding bundle on changes in #{Enum.join(@watched_dirs, ", ")}")
        {:ok, %{watcher: watcher, timer: nil}}

      other ->
        Logger.warning("[scoria] asset watcher disabled (no watchable dirs / FileSystem error: #{inspect(other)})")
        :ignore
    end
  end

  @impl true
  def handle_info({:file_event, watcher, {path, _events}}, %{watcher: watcher} = state) do
    if String.ends_with?(path, [".css", ".js"]) do
      {:noreply, schedule_rebuild(state)}
    else
      {:noreply, state}
    end
  end

  def handle_info({:file_event, watcher, :stop}, %{watcher: watcher} = state) do
    {:noreply, state}
  end

  def handle_info(:rebuild, state) do
    rebuild()
    {:noreply, %{state | timer: nil}}
  end

  # Rebuild once, @debounce_ms after the LAST change in a burst (reset the timer
  # on each event so a multi-file save triggers a single build).
  defp schedule_rebuild(%{timer: timer} = state) do
    if timer, do: Process.cancel_timer(timer)
    %{state | timer: Process.send_after(self(), :rebuild, @debounce_ms)}
  end

  defp rebuild do
    Mix.Task.rerun(@task, [])
  rescue
    e -> Logger.error("[scoria] asset rebuild failed: #{Exception.message(e)}")
  end
end
