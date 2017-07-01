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
  set vm_args: "rel/templates/vm.args"
  set overlays: [
    {:copy, "priv/nodes.txt", "nodes.txt"},
    {:copy, "priv/cacert.pem", "cacert.pem"},
    {:copy, "priv/cert.pem", "cert.pem"},
    {:copy, "priv/key.pem", "key.pem"}
  ]
end

