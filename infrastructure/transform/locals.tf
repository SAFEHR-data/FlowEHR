locals {
  sql_server_features_admin_username = "adminuser"
  storage_account_name               = "dbfs${var.truncated_naming_suffix}"
  adb_linked_service_name            = "ADBLinkedServiceViaMSI"

  python_file_local_path = "../../transform/features"
  python_file_dbfs_path  = "dbfs:"
  python_file_name       = "entrypoint.py"

  whl_file_local_path = "../../transform/features/dist"
  whl_file_dbfs_path  = "dbfs:"
  whl_file_name       = "src-0.0.1-py3-none-any.whl"
}
