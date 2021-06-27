defmodule Flo.Util.Lua do
  @moduledoc false

  def execute(context, code) do
    state =
      context
      |> Enum.reduce(:luerl_sandbox.init(), fn {k, v}, state ->
        {value, state} = :luerl.encode(v, state)
        :luerl_emul.set_global_key(k, value, state)
      end)

    case :luerl_sandbox.run(code, state, 1000) do
      {[value], state} ->
        {:ok, :luerl.decode(value, state) |> decode()}

      {value, _state} when is_list(value) ->
        {:error, "multi value return not supported"}

      _ ->
        {:error, "decode_error"}
    end
  end

  defp decode(value) when is_list(value) do
    cond do
      value |> Enum.map(&Kernel.elem(&1, 0)) |> Enum.all?(&is_integer/1) ->
        Enum.unzip(value) |> Kernel.elem(1) |> Enum.map(&decode/1)

      value |> Enum.map(&Kernel.elem(&1, 0)) |> Enum.all?(&is_binary/1) ->
        value |> Enum.map(fn {x, y} -> {x, decode(y)} end) |> Map.new()

      true ->
        {string_items, number_items} = value |> Enum.split_with(fn {x, _} -> is_binary(x) end)
        map = string_items |> Enum.map(fn {x, y} -> {x, decode(y)} end) |> Map.new()

        number_items
        |> Enum.reduce(map, fn {index, value}, acc ->
          acc |> Map.put(index, decode(value))
        end)
    end
  end

  defp decode(value), do: value
end
