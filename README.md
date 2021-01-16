# Virta
Ecosystem for event-driven applications

[source](https://github.com/sarat1669/virta) | [documentation](https://hexdocs.pm/virta/Virta.html)

## Installation

```elixir
def deps do
  [{:virta, "~> 1.0"}]
end
```

Ensure `:virta` is started before your application:
```elixir
def application do
  [applications: [:virta]]
end
```