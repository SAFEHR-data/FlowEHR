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

from pyspark.context import SparkContext
from pyspark.sql.session import SparkSession

from src.transform import example_transform


sc = SparkContext.getOrCreate()
spark = SparkSession(sc)


# For an ADF pipeline that triggers a Databricks job though,
# we have to define an entrypoint file (I haven't found another way.)
if __name__ == "__main__":
    df = spark.createDataFrame([(1,), (2,), (3,), (2,), (3,)], ["value"])
    # This is an example of how transform from a built Python wheel library
    # will be used in the entrypoint pipeline
    out_df = example_transform(df)
    out_df.display()
