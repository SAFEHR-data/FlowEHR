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

from src.transform import example_transform
from .helpers.pyspark_test import PySparkTest


class ExampleTransformTest(PySparkTest):
    def test_example(self):
        input_df = self.spark.createDataFrame([(1,), (2,), (3,), (2,), (3,)], ["value"])

        output_df = example_transform(input_df)

        expected_df = self.spark.createDataFrame(
            [(1, 1), (2, 2), (3, 2)], ["value", "count"]
        )

        self.assertSetEqual(set(expected_df.columns), set(output_df.columns))
        self.assertEqual(expected_df.collect(), output_df.collect())
