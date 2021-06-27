defmodule Flo.Script do
  @derive Jason.Encoder

  use Accessible

  defmodule Language do
    @behaviour Construct.Type

    @entries ["VANILLA", "LUA", "LIQUID"]

    @entries
    |> Enum.each(fn entry ->
      def unquote(:"#{entry |> String.downcase() |> Macro.underscore()}")() do
        unquote(entry)
      end
    end)

    def cast(value) when value in @entries do
      {:ok, value}
    end

    def cast(_), do: :error
  end

  use Construct do
    field(:source, :any)
    field(:language, Flo.Script.Language)
  end

  # TODO: handle errors
  def execute(%Flo.Script{language: "VANILLA", source: source}, _context) do
    {:ok, source}
  end

  def execute(%Flo.Script{language: "LUA", source: source}, %Flo.Context{} = context) do
    context
    |> Jason.encode!()
    |> Jason.decode!()
    |> Flo.Util.Lua.execute(source)
  end

  def execute(%Flo.Script{language: "LIQUID", source: source}, %Flo.Context{} = context) do
    context =
      context
      |> Jason.encode!()
      |> Jason.decode!()

    {:ok, template} = Solid.parse(source)
    {:ok, Solid.render(template, context) |> to_string}
  end
end
