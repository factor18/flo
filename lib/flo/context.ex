defmodule Flo.Context do
  @derive Jason.Encoder

  use Accessible

  defmodule Stimulus do
    @derive Jason.Encoder

    use Accessible

    use Construct do
      field :ref, :string
      field :configs, :map, default: %{}
      field :outports, :map, default: nil
    end
  end

  defmodule Element do
    @derive Jason.Encoder

    use Accessible

    use Construct do
      field :inports, :map, default: %{}
      field :outports, :map, default: nil
    end
  end

  alias Flo.Context
  alias Context.{Element, Stimulus}

  use Construct do
    field :stimulus, Stimulus, default: nil
    field :elements, {:map, Element}, default: []
  end

  def new(ref, %Flo.Workflow{stimuli: stimuli} = workflow) do
    stimulus =
      stimuli
      |> Enum.find(fn(%Flo.Stimulus{} = stimulus) -> stimulus.ref == ref end)

    stimulus = %Stimulus{ref: ref, configs: stimulus.configs |> parse_ports() }

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

  def resolve(context, %Flo.Element{ref: ref, inports: inports}) do
    element_context = %Element{inports: inports |> parse_ports(context)}
    context |> Kernel.put_in([:elements, ref], element_context)
  end

  def update_outports(context, %Flo.Element{ref: ref}, outports) do
    context |> Kernel.put_in([:elements, ref, :outports], outports)
  end

  defp parse_ports(ports, context \\ %Context{}) do
    ports
    |> Enum.map(fn {key, value} ->
      {:ok, value} = Flo.Script.execute(value, context)
      {key, value}
    end)
    |> Map.new
  end
end
