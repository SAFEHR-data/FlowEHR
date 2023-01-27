from pyspark.context import SparkContext
from pyspark.sql.session import SparkSession

from src.transform import example_transform


sc = SparkContext.getOrCreate()
spark = SparkSession(sc)


if __name__ == "__main__":
    df = spark.createDataFrame([(1, ), (2, ), (3, ), (2, ), (3, )],
                               ["value"])
    out_df = example_transform(df)
    out_df.display()
