include "root" {
  path = find_in_parent_folders()
}

dependency "core" {
  config_path = "${get_parent_terragrunt_dir()}/core"
}
