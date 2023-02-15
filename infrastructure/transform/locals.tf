locals {
  activities_file = "activities.json"
  artifacts_dir = "artifacts"

  # Example value: [ "../../transform/pipelines/hello-world" ]
  pipeline_dirs = toset([
    for activity_file in fileset(path.module, "../../transform/pipelines/**/${local.activities_file}"): dirname(activity_file)
  ])

  # Example value: [ { "artifact_path" = "path/to/entrypoint.py", "pipeline" = "hello-world" } ]
  artifacts = flatten([
    for pipeline in local.pipeline_dirs: [
      for artifact in fileset("${pipeline}/${local.artifacts_dir}", "*") : {
        artifact_path = "${pipeline}/${local.artifacts_dir}/${artifact}"
        pipeline = basename(pipeline)
      }
    ]
  ])
  storage_account_name = "dbfs${var.truncated_naming_suffix}"
}
