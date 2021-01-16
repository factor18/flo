defmodule Virta do
  def hello() do
    :world
  end

  def test do
    app = ~s({
      "name": "virta",
      "version": "0.0.1",
      "description": "Virta Application",
      "triggers": [
        {
          "id": "log_timer",
          "ref": "virta:plugins:trigger:interval",
          "settings": [
            {"name": "delay", "value": 5000}
          ]
        }
      ],
      "tasks": [
        {
          "id": "hello_log",
          "ref": "virta:plugins:component:log",
          "settings": [
            {"name": "useStdio", "value": true}
          ],
          "inports": [
            {"name": "message", "value": "Hello"}
          ]
        },
        {
          "id": "delay_1000",
          "ref": "virta:plugins:component:delay",
          "settings": [
            {"name": "delay", "value": 1000}
          ],
          "inports": []
        },
        {
          "id": "world_log",
          "ref": "virta:plugins:component:log",
          "settings": [
            {"name": "useStdio", "value": true}
          ],
          "inports": [
            {"name": "message", "value": "World"}
          ]
        }
      ],
      "links": [
        {"from": "log_timer", "to": "hello_log"},
        {"from": "hello_log", "to": "delay_1000"},
        {"from": "delay_1000", "to": "world_log"}
      ]
    })

    Virta.AppRegistry.register(
      Poison.decode!(app, as: %Virta.App{
        triggers: [%Virta.Trigger{
          outports: [%Virta.Pair{}],
          settings: [%Virta.Pair{}],
        }],
        tasks: [%Virta.Task{
          inports:  [%Virta.Pair{}],
          outports: [%Virta.Pair{}],
          settings: [%Virta.Pair{}],
        }],
        links: [%Virta.Link{}],
      })
    )
  end
end
