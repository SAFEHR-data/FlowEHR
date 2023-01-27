"""
The entry point of the pipeline Python wheel
"""


from pyspark.context import SparkContext
from pyspark.sql.session import SparkSession
from pyspark.sql import DataFrame


sc = SparkContext.getOrCreate()
spark = SparkSession(sc)


def example_transform(df: DataFrame) -> DataFrame:
    return df.groupby("value").count()
