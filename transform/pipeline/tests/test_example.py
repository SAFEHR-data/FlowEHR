from src.transform import example_transform
from .helpers.pyspark_test import PySparkTest


class ExampleTransformTest(PySparkTest):
    def test_example(self):
        input_df = self.spark.createDataFrame(
            [(1, ), (2, ), (3, ), (2, ), (3, )],
            ["value"])

        output_df = example_transform(input_df)

        expected_df = self.spark.createDataFrame(
            [(1, 1), (2, 2), (3, 2)],
            ["value", "count"])

        self.assertSetEqual(set(expected_df.columns), set(output_df.columns))
        self.assertEqual(expected_df.collect(), output_df.collect())
