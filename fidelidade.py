from pyspark.sql import SparkSession
from pyspark.sql.types import DateType
from pyspark.sql.types import DoubleType
from pyspark.sql.functions import asc
from pyspark.sql.functions import sum
from pyspark.sql.functions import date_format
from pyspark.sql.functions import avg
from pyspark.sql.functions import col
from pyspark.sql.functions import max
from pyspark.sql.functions import count

spark = SparkSession \
	.builder \
	.appName("PySpark example") \
	.getOrCreate()

#IMPORTANT: TENS DE FAZER DOWNLOAD DO CSV
# GOAL: Numero medio de views ate uma compra
df = spark \
	.read \
	.option("header", "false") \
	.csv("database/smallerLargeFile_3.csv")

avg_by_view = df \
		.select(col("_c1").alias("event_type"), col("_c8").alias("user_session") \
		.filter(col("user_session").isNotNull()) \
		.filter(col("event_type = purchase" or col("event_type = view"))) \
		.groupBy("user_session", "event_type") \
		.count() \
		.groupBy("user_id", "category_id") \
		.agg(max("count").alias("max"), sum("count").alias("total")) \
		.agg(avg(col("max") / col("total"))).show()
		
spark.stop()


