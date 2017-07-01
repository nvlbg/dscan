# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    default_release: :default,
    default_environment: Mix.env()


environment :dev do
  set dev_mode: true
  set include_erts: false
end

environment :prod do
  set include_erts: true
  set include_src: false
end

release :server do
  set version: current_version(:server)
  set applications: [
    :runtime_tools
  ]
  set overlays: [
    {:template, "rel/templates/vm.args", "releases/<%= release_version %>/vm.args"},
    {:template, "rel/templates/nodes.txt", "nodes.txt"},
    {:template, "rel/templates/cacert.pem", "cacert.pem"},
    {:template, "rel/templates/cert.pem", "cert.pem"},
    {:template, "rel/templates/key.pem", "key.pem"}
  ]
  set overlay_vars: [
    public_ip: System.get_env() |> Map.fetch!("PUBLIC_IP"),
    erlang_cookie: System.get_env() |> Map.fetch!("ERLANG_COOKIE"),
    key_password: System.get_env() |> Map.fetch!("KEY_PASSWORD")
  ]
end

