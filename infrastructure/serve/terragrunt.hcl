include "root" {
  path = find_in_parent_folders()
}

dependency "core" {
  config_path = "../core"
}

inputs = {
  core_rg_name     = dependency.core.outputs.core_rg_name
  core_rg_location = dependency.core.outputs.core_rg_location
  core_kv_id       = dependency.core.outputs.core_kv_id
}
