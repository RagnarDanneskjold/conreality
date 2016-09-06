# This is free and unencumbered software released into the public domain.

defmodule Conreality.Machinery.Camera do
  @moduledoc """
  Camera support.
  """

  alias Conreality.Machinery
  require Logger

  defmodule State do
    defstruct path: nil

    @type t :: struct
  end

  @spec start_link(non_neg_integer) :: {:ok, port} | {:error, any}
  def start_link(video_id) when is_integer(video_id) do
    start_link("/dev/video#{video_id}")
  end

  @spec start_link(binary) :: {:ok, port} | {:error, any}
  def start_link(device_path) when is_binary(device_path) do
    Logger.info "Starting camera driver for #{device_path}..."

    #["v4l2-camera.py", device_path]
    ["ping-loop.py", "10"]
    |> Machinery.InputDriver.start_script(__MODULE__, %State{path: device_path})
  end

  @spec handle_exit(integer, State.t) :: any
  def handle_exit(code, state) do
    Logger.warn "Camera driver for #{state.path} exited with code #{code}."
  end

  @spec handle_input(term, State.t) :: State.t
  def handle_input(event, state) do
    Logger.warn "Camera driver for #{state.path} ignored unexpected input: #{inspect event}" # TODO

    state
  end
end