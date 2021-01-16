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
            {"name": "message", "value": "Hello World"}
          ]
        },
        {
          "id": "world_log",
          "ref": "virta:plugins:component:log",
          "settings": [
            {"name": "useStdio", "value": true}
          ],
          "inports": [
            {"name": "message", "value": "3, 2, 1..."}
          ]
        }
      ],
      "links": [
        {"from": "log_timer", "to": "hello_log"},
        {"from": "log_timer", "to": "world_log"}
      ]
    })

    Virta.AppRegistry.register(
      IO.inspect Poison.decode!(app, as: %Virta.App{
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
