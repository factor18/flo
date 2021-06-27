defmodule Flo.Util.ModuleLoader do
  @moduledoc false

  # Loads all modules that extend a given module in the current code path.
  def get_elements(element_type) when is_atom(element_type) do
    available_modules(element_type) |> Enum.reduce([], &load_element/2)
  end

  defp load_element(module, modules) do
    if Code.ensure_loaded?(module), do: [module | modules], else: modules
  end

  defp available_modules(element_type) do
    # Ensure the current projects code path is loaded
    Path.wildcard(Path.join(["./**/ebin/**/*.beam"]))
    # Parse the BEAM for behaviour implementations
    |> Stream.map(fn path ->
      {:ok, {mod, chunks}} = :beam_lib.chunks('#{path}', [:attributes])
      {mod, get_in(chunks, [:attributes, :behaviour])}
    end)
    |> Stream.filter(fn {_mod, behaviours} ->
      is_list(behaviours) && element_type in behaviours
    end)
    |> Enum.uniq()
    |> Enum.map(fn {module, _} -> module end)
  end
end
