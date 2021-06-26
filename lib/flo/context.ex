defmodule Flo.Context do
  @derive Jason.Encoder

  use Accessible

  defmodule Stimulus do
    @derive Jason.Encoder

    use Accessible

    use Construct do
      field :ref, :string
      field :configs, :map, default: %{}
      field :outports, :map, default: %{}
    end
  end

  defmodule Element do
    @derive Jason.Encoder

    use Accessible

    use Construct do
      field :inports, :map, default: %{}
      field :outports, :map, default: %{}
    end
  end

  alias Flo.Context
  alias Context.{Element, Stimulus}

  use Construct do
    field :stimulus, Stimulus, default: nil
    field :elements, {:map, Flo.Context.Element}, default: []
  end

  def new(ref, %Flo.Workflow{stimuli: stimuli} = workflow) do
    stimulus =
      stimuli
      |> Enum.find(fn(%Flo.Stimulus{} = stimulus) -> stimulus.ref == ref end)

    stimulus = %Flo.Context.Stimulus{ref: ref, configs: stimulus.configs |> parse_ports() }

    elements =
      workflow.elements
      |> Enum.reduce(
        %{},
        fn (%Flo.Element{inports: inports} = element, acc) ->
          acc |> Map.put(element.ref, %Element{inports: inports |> parse_ports()})
        end
      )

    %Context{stimulus: stimulus, elements: elements}
  end

  defp parse_ports(ports, context \\ %Flo.Context{}) do
    ports
    |> Enum.map(fn {key, value} ->
      {:ok, value} = Flo.Script.execute(value, context)
      {key, value}
    end)
    |> Map.new
  end
end
