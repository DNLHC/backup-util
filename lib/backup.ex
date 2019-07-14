defmodule Backup do
  @backups_dir Path.expand("~/Documents/DSR_backups")
  @saves_dir Path.expand("~/Documents/DS_TEST")
  @max_backups 20

  def init do
    if not File.exists?(@backups_dir) do
      File.mkdir(@backups_dir)
    end

    if not File.exists?(@saves_dir) or not File.dir?(@saves_dir) do
      raise "Couldn't find original saves folder at: \n#{@saves_dir}"
    else
      backup(true)
      clean()
    end
  end

  def backup(initial \\ false) do
    time_now = System.system_time(:second)

    get_saves_list(@saves_dir)
    |> Enum.each(fn path_dir ->
      save_backup_dir = Path.join(@backups_dir, path_dir)
      save_dir = Path.join(@saves_dir, path_dir)

      if not File.exists?(save_backup_dir) do
        File.mkdir(save_backup_dir)
      end

      File.ls!(save_dir)
      |> Enum.map(fn file -> Path.join(save_dir, file) end)
      |> Enum.filter(fn file ->
        stat = File.stat!(file, time: :posix)
        not File.dir?(file) and (initial or time_now - stat.mtime < 600)
      end)
      |> Enum.each(fn file_path ->
        backup_name = get_backup_name(file_path)
        created_at = get_current_time()

        File.cp!(file_path, Path.join(save_backup_dir, backup_name))
        IO.puts("#{created_at}: Created backup #{backup_name}")
      end)
    end)
  end

  def get_backup_name(file) do
    timestamp = get_timestamp()
    extname = Path.extname(file)
    basename = Path.basename(file, extname)

    "#{timestamp}_#{basename}#{extname}"
  end

  def get_current_time do
    Time.utc_now() |> Time.truncate(:second) |> Time.to_string()
  end

  def get_saves_list(path) do
    File.ls!(path) |> Enum.filter(fn file -> File.dir?(Path.join(path, file)) end)
  end

  def get_timestamp do
    now = DateTime.utc_now()
    date = Enum.join([now.year, now.month, now.day], "-")
    time = Enum.join([now.hour, now.minute, now.second], "-")

    Enum.join([date, time], "T")
  end

  def clean do
    get_saves_list(@backups_dir)
    |> Enum.each(fn path_dir ->
      saves_dir = Path.join(@backups_dir, path_dir)
      list = File.ls!(saves_dir)
      amount = length(list)

      if amount > @max_backups do
        range = amount - @max_backups

        list
        |> Enum.sort()
        |> Enum.slice(0, range)
        |> Enum.each(fn file -> File.rm!(Path.join(saves_dir, file)) end)

        IO.puts("#{get_current_time()}: Removed #{range} backup files")
      end
    end)
  end
end
