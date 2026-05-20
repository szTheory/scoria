import Config

if config_env() == :prod do
  config :scoria, Oban,
    queues: [
      system: String.to_integer(System.get_env("OBAN_SYSTEM_CONCURRENCY") || "10"),
      inference: String.to_integer(System.get_env("OBAN_INFERENCE_CONCURRENCY") || "20"),
      evals: String.to_integer(System.get_env("OBAN_EVALS_CONCURRENCY") || "50")
    ]
end
