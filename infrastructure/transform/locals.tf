#  Copyright (c) University College London Hospitals NHS Foundation Trust
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# superficial change to trigger build.

locals {
  activities_file = "activities.json"
  artifacts_dir   = "artifacts"

  all_activities_files = fileset(path.module, "../../transform/pipelines/**/${local.activities_file}")

  # Example value: [ "../../transform/pipelines/hello-world" ]
  pipeline_dirs = toset([
    for activity_file in all_activities_files : dirname(activity_file)
  ])

  # Example value: [ { "artifact_path" = "path/to/entrypoint.py", "pipeline" = "hello-world" } ]
  artifacts = flatten([
    for pipeline in local.pipeline_dirs : [
      for artifact in fileset("${pipeline}/${local.artifacts_dir}", "*") : {
        artifact_path = "${pipeline}/${local.artifacts_dir}/${artifact}"
        pipeline      = basename(pipeline)
      }
    ]
  ])
  storage_account_name = "dbfs${var.truncated_naming_suffix}"

  spark_version = yamldecode(file("../../config.transform.yaml")).spark_version
}
