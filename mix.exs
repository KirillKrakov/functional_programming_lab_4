defmodule Lab4.MixProject do
  use Mix.Project

  def project do
    [
      app: :lab4_v2,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Lab4.Application, []},
      extra_applications: [:logger, :mnesia]
    ]
  end

  defp deps do
    []
  end
end
